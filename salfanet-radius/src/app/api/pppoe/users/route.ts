import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { sendAdminCreateUser } from '@/lib/whatsapp-notifications';
import { changePPPoERateLimit } from '@/lib/mikrotik-rate-limit';
import { logActivity } from '@/lib/activity-log';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { redisDel, RedisKeys } from '@/lib/redis';
import { generateUniqueReferralCode } from '@/lib/referral';

// GET - List all PPPoE users
export async function GET(request: NextRequest) {
  // Check authentication
  const session = await getServerSession(authOptions);
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    
    // Build where clause
    let whereClause: any = {};
    if (status) {
      // If requesting specific status, use it
      whereClause.status = status;
    } else {
      // If no status specified, exclude 'stop' from main customer list
      whereClause.status = { not: 'stop' };
    }
    
    const users = await prisma.pppoeUser.findMany({
      where: whereClause,
      include: {
        profile: true,
        router: true,
        area: true,
        odpAssignment: {
          include: {
            odp: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Check online status for each user
    const usersWithOnlineStatus = await Promise.all(
      users.map(async (user) => {
        // Check if user has an active session in radacct
        const activeSession = await prisma.radacct.findFirst({
          where: {
            username: user.username,
            acctstoptime: null, // Session is still active
          },
        });

        return {
          ...user,
          isOnline: !!activeSession,
        };
      })
    );

    return NextResponse.json({
      users: usersWithOnlineStatus,
      count: usersWithOnlineStatus.length,
    });
  } catch (error) {
    console.error('Get PPPoE users error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST - Create new PPPoE user
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      username,
      password,
      profileId,
      routerId,
      areaId,
      name,
      phone,
      email,
      address,
      latitude,
      longitude,
      ipAddress,
      macAddress,
      comment,
      expiredAt,
      subscriptionType,
      billingDay,
      idCardNumber,
      idCardPhoto,
      installationPhotos,
      followRoad,
    } = body;

    // Validate required fields
    if (!username || !password || !profileId || !name || !phone) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Check if username already exists
    const existingUser = await prisma.pppoeUser.findUnique({
      where: { username },
    });

    if (existingUser) {
      return NextResponse.json(
        { error: `Username "${username}" already exists` },
        { status: 400 }
      );
    }

    // Generate unique 8-digit customer ID
    let customerId: string = '';
    let isUnique = false;
    while (!isUnique) {
      // Generate random 8-digit number
      customerId = Math.floor(10000000 + Math.random() * 90000000).toString();
      
      // Check if it's unique
      const existingCustomerId = await prisma.pppoeUser.findUnique({
        where: { customerId },
      });
      
      if (!existingCustomerId) {
        isUnique = true;
      }
    }

    // Get profile to retrieve groupName
    const profile = await prisma.pppoeProfile.findUnique({
      where: { id: profileId },
    });

    if (!profile) {
      return NextResponse.json({ error: 'Profile not found' }, { status: 404 });
    }

    // Calculate expiredAt based on subscription type
    let finalExpiredAt: Date;
    const now = new Date();
    
    if (subscriptionType === 'POSTPAID') {
      // POSTPAID: expiredAt = billingDay bulan berikutnya (auto-calculated)
      finalExpiredAt = new Date(now);
      finalExpiredAt.setMonth(finalExpiredAt.getMonth() + 1); // Next month
      const validBillingDay = billingDay ? Math.min(Math.max(parseInt(billingDay), 1), 31) : 1;
      finalExpiredAt.setDate(validBillingDay);
      finalExpiredAt.setHours(23, 59, 59, 999);
    } else {
      // PREPAID: expiredAt bisa manual atau auto dari profile validity
      if (expiredAt) {
        finalExpiredAt = new Date(expiredAt);
      } else {
        finalExpiredAt = new Date(now);
        if (profile.validityUnit === 'MONTHS') {
          finalExpiredAt.setMonth(finalExpiredAt.getMonth() + profile.validityValue);
        } else {
          finalExpiredAt.setDate(finalExpiredAt.getDate() + profile.validityValue);
        }
        finalExpiredAt.setHours(23, 59, 59, 999);
      }
    }

    // Verify router if provided
    if (routerId) {
      const router = await prisma.router.findUnique({
        where: { id: routerId },
      });
      if (!router) {
        return NextResponse.json({ error: 'Router not found' }, { status: 404 });
      }
    }

    // Create user
    const user = await prisma.pppoeUser.create({
      data: {
        id: crypto.randomUUID(),
        username,
        customerId, // Auto-generated 8-digit ID
        password,
        profileId,
        routerId: routerId || null,
        areaId: areaId || null,
        name,
        phone,
        email: email || null,
        address: address || null,
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        ipAddress: ipAddress || null,
        macAddress: macAddress || null,
        comment: comment || null,
        expiredAt: finalExpiredAt,
        status: 'active',
        subscriptionType: subscriptionType || 'POSTPAID',
        billingDay: billingDay ? Math.min(Math.max(parseInt(billingDay), 1), 31) : 1,
        idCardNumber: idCardNumber || null,
        idCardPhoto: idCardPhoto || null,
        installationPhotos: installationPhotos ? installationPhotos : null,
        followRoad: followRoad ? true : false,
        referralCode: await generateUniqueReferralCode(),
      } as any,
    });

    // Sync to FreeRADIUS
    try {
      // Get router info if routerId is provided
      let router = null;
      if (routerId) {
        router = await prisma.router.findUnique({
          where: { id: routerId },
          select: { id: true, nasname: true },
        });
      }

      // 1. Create radcheck entry for password (Cleartext-Password)
      await prisma.radcheck.create({
        data: {
          username,
          attribute: 'Cleartext-Password',
          op: ':=',
          value: password,
        },
      });

      // 2. If router is assigned, add NAS-IP-Address to restrict to specific router
      if (router) {
        await prisma.radcheck.create({
          data: {
            username,
            attribute: 'NAS-IP-Address',
            op: '==',
            value: router.nasname,
          },
        });
      }

      // 3. Create radusergroup entry to assign user to profile group
      await prisma.radusergroup.create({
        data: {
          username,
          groupname: profile.groupName,
          priority: 0,
        },
      });

      // 4. Optional: Add static IP to radreply if specified
      if (ipAddress) {
        await prisma.radreply.create({
          data: {
            username,
            attribute: 'Framed-IP-Address',
            op: ':=',
            value: ipAddress,
          },
        });
      }

      // Mark as synced
      await prisma.pppoeUser.update({
        where: { id: user.id },
        data: {
          syncedToRadius: true,
          lastSyncAt: new Date(),
        },
      });

      // Get area name if areaId provided
      let areaName = undefined;
      if (areaId) {
        const area = await prisma.pppoeArea.findUnique({
          where: { id: areaId },
          select: { name: true },
        });
        areaName = area?.name;
      }

      // Get company info for notifications
      const company = await prisma.company.findFirst();

      // Send WhatsApp notification
      try {
        await sendAdminCreateUser({
          customerName: name,
          customerPhone: phone,
          customerId: user.customerId || undefined,
          username,
          password,
          profileName: profile.name,
          area: areaName,
        });
        console.log(`✅ WhatsApp notification sent to ${phone}`);
      } catch (waError) {
        console.error('WhatsApp notification error:', waError);
      }

      // Send Email notification if email provided
      if (email && company) {
        try {
          const { EmailService } = await import('@/lib/email');
          await EmailService.sendAdminCreateUser({
            email,
            customerName: name,
            username,
            password,
            profileName: profile.name,
            area: areaName,
            companyName: company.name,
            companyPhone: company.phone || '',
          });
          console.log(`✅ Email notification sent to ${email}`);
        } catch (emailError) {
          console.error('Email notification error:', emailError);
        }
      }

      // Log activity
      try {
        const session = await getServerSession(authOptions);
        await logActivity({
          userId: (session?.user as any)?.id,
          username: (session?.user as any)?.username || 'Admin',
          userRole: (session?.user as any)?.role,
          action: 'CREATE_PPPOE_USER',
          description: `Created PPPoE user: ${username}`,
          module: 'pppoe',
          status: 'success',
          request,
          metadata: {
            username,
            profileId,
            profileName: profile.name,
            routerId,
          },
        });
      } catch (logError) {
        console.error('Activity log error:', logError);
      }

      return NextResponse.json({
        success: true,
        user: {
          ...user,
          syncedToRadius: true,
        },
      }, { status: 201 });
    } catch (syncError: any) {
      console.error('RADIUS sync error:', syncError);
      return NextResponse.json({
        success: true,
        user,
        warning: 'User created but RADIUS sync failed',
      }, { status: 201 });
    }
  } catch (error) {
    console.error('Create PPPoE user error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// PUT - Update PPPoE user
export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      id,
      username,
      password,
      profileId,
      routerId,
      areaId,
      name,
      phone,
      email,
      address,
      latitude,
      longitude,
      ipAddress,
      macAddress,
      comment,
      expiredAt,
      status,
      subscriptionType,
      billingDay,
      autoRenewal,
      idCardNumber,
      idCardPhoto,
      installationPhotos,
      followRoad,
    } = body;

    if (!id) {
      return NextResponse.json({ error: 'User ID is required' }, { status: 400 });
    }

    const currentUser = await prisma.pppoeUser.findUnique({
      where: { id },
      include: { profile: true },
    });

    if (!currentUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Check if username changed and new one already exists
    if (username && username !== currentUser.username) {
      const existingUser = await prisma.pppoeUser.findUnique({
        where: { username },
      });

      if (existingUser) {
        return NextResponse.json(
          { error: `Username "${username}" already exists` },
          { status: 400 }
        );
      }
    }

    // Get new profile if changed
    let newProfile = currentUser.profile;
    if (profileId && profileId !== currentUser.profileId) {
      const profile = await prisma.pppoeProfile.findUnique({
        where: { id: profileId },
      });

      if (!profile) {
        return NextResponse.json({ error: 'Profile not found' }, { status: 404 });
      }
      newProfile = profile;
    }

    // Verify router if provided
    if (routerId) {
      const router = await prisma.router.findUnique({
        where: { id: routerId },
      });
      if (!router) {
        return NextResponse.json({ error: 'Router not found' }, { status: 404 });
      }
    }

    // Update user
    const user = await prisma.pppoeUser.update({
      where: { id },
      data: {
        ...(username && { username }),
        ...(password && { password }),
        ...(profileId && { profileId }),
        ...(routerId !== undefined && { routerId: routerId || null }),
        ...(areaId !== undefined && { areaId: areaId || null }),
        ...(name && { name }),
        ...(phone && { phone }),
        ...(email !== undefined && { email }),
        ...(address !== undefined && { address }),
        ...(latitude !== undefined && { latitude: latitude ? parseFloat(latitude) : null }),
        ...(longitude !== undefined && { longitude: longitude ? parseFloat(longitude) : null }),
        ...(ipAddress !== undefined && { ipAddress }),
        ...(macAddress !== undefined && { macAddress }),
        ...(comment !== undefined && { comment }),
        ...(expiredAt && { expiredAt: new Date(expiredAt) }),
        ...(status && { status }),
        ...(subscriptionType && { subscriptionType }),
        ...(billingDay !== undefined && { billingDay: Math.min(Math.max(parseInt(billingDay), 1), 28) }),
        ...(autoRenewal !== undefined && { autoRenewal }),
        ...(idCardNumber !== undefined && { idCardNumber: idCardNumber || null }),
        ...(idCardPhoto !== undefined && { idCardPhoto: idCardPhoto || null }),
        ...(installationPhotos !== undefined && { installationPhotos }),
        ...(followRoad !== undefined && { followRoad: !!followRoad }),
      } as any,
    });

    // Re-sync to RADIUS if critical fields changed
    if (username || password || profileId || ipAddress || routerId !== undefined) {
      try {
        const oldUsername = currentUser.username;
        const newUsername = username || currentUser.username;

        // Delete old RADIUS entries
        await prisma.radcheck.deleteMany({
          where: { username: oldUsername },
        });
        await prisma.radreply.deleteMany({
          where: { username: oldUsername },
        });
        await prisma.radusergroup.deleteMany({
          where: { username: oldUsername },
        });

        // Get router info if routerId is provided
        const finalRouterId = routerId !== undefined ? routerId : currentUser.routerId;
        let router = null;
        if (finalRouterId) {
          router = await prisma.router.findUnique({
            where: { id: finalRouterId },
            select: { id: true, nasname: true },
          });
        }

        // Create new RADIUS entries
        await prisma.radcheck.create({
          data: {
            username: newUsername,
            attribute: 'Cleartext-Password',
            op: ':=',
            value: password || currentUser.password,
          },
        });

        // Add NAS-IP-Address if router is assigned
        if (router) {
          await prisma.radcheck.create({
            data: {
              username: newUsername,
              attribute: 'NAS-IP-Address',
              op: '==',
              value: router.nasname,
            },
          });
        }

        await prisma.radusergroup.create({
          data: {
            username: newUsername,
            groupname: newProfile.groupName,
            priority: 0,
          },
        });

        // Add static IP to radreply if specified
        const finalIpAddress = ipAddress !== undefined ? ipAddress : currentUser.ipAddress;
        if (finalIpAddress) {
          await prisma.radreply.create({
            data: {
              username: newUsername,
              attribute: 'Framed-IP-Address',
              op: ':=',
              value: finalIpAddress,
            },
          });
        }

        // Mark as synced
        await prisma.pppoeUser.update({
          where: { id },
          data: {
            syncedToRadius: true,
            lastSyncAt: new Date(),
          },
        });

        // If profile changed, apply new rate limit via CoA — avoid disconnecting the user.
        // MikroTik does NOT support changing PPP profile via CoA, but DOES support Mikrotik-Rate-Limit.
        // Strategy: apply new rate limit via API queue or CoA; disconnect only as last resort.
        const profileChanged = profileId && profileId !== currentUser.profileId;
        if (profileChanged && newProfile) {
          console.log(`[User Update] Profile changed for user ${newUsername}, applying new rate limit via CoA...`);

          // Find active session
          const activeSession = await prisma.radacct.findFirst({
            where: { username: oldUsername, acctstoptime: null },
            select: { acctsessionid: true, nasipaddress: true, framedipaddress: true },
          });

          if (activeSession) {
            // Get full router config
            const routerRow = await prisma.router.findFirst({
              where: {
                OR: [
                  { nasname: activeSession.nasipaddress ?? '' },
                  { ipAddress: activeSession.nasipaddress ?? '' },
                ],
              },
              select: { ipAddress: true, nasname: true, port: true, username: true, password: true, secret: true },
            }) || await prisma.router.findFirst({
              where: { isActive: true },
              select: { ipAddress: true, nasname: true, port: true, username: true, password: true, secret: true },
            });

            if (routerRow) {
              // Use new profile's rateLimit (e.g., "10M/5M") for the live rate change
              const newRateLimit = newProfile.rateLimit || `${newProfile.downloadSpeed}M/${newProfile.uploadSpeed}M`;

              const result = await changePPPoERateLimit(
                {
                  ipAddress: routerRow.ipAddress,
                  nasname: routerRow.nasname,
                  port: routerRow.port,
                  username: routerRow.username,
                  password: routerRow.password,
                  secret: routerRow.secret,
                },
                oldUsername,
                newRateLimit,
                {
                  acctSessionId: activeSession.acctsessionid || undefined,
                  nasIpAddress: routerRow.ipAddress,
                  framedIpAddress: activeSession.framedipaddress || undefined,
                },
                { allowDisconnect: true }
              );

              console.log(`[User Update] Rate limit change result for ${newUsername}:`, result);

              return NextResponse.json({
                success: true,
                user,
                profileChanged: true,
                rateChanged: result.success,
                method: result.method,
                message: result.success
                  ? result.method === 'disconnect'
                    ? 'Profile changed. User disconnected and will reconnect with new rate limit.'
                    : `Profile changed. Rate limit updated to ${newRateLimit} without disconnect.`
                  : `Profile changed in DB but live rate limit change failed: ${result.error}`,
              });
            }
          }
        }
      } catch (syncError) {
        console.error('RADIUS re-sync error:', syncError);
      }
    }

    // If status changed via general edit, invalidate auth cache immediately
    // so FreeRADIUS authorize hook picks up the new status without waiting for
    // the 60-second Redis TTL.
    if (status && status !== currentUser.status) {
      await redisDel(RedisKeys.radiusAuth(currentUser.username));
      // For blocking/stopping/isolating: send CoA disconnect to terminate the
      // current session right away (user would otherwise stay online until
      // their PPPoE session naturally expires).
      if (['blocked', 'stop', 'isolated'].includes(status)) {
        try {
          const { disconnectPPPoEUser } = await import('@/lib/services/coaService');
          await disconnectPPPoEUser(currentUser.username).catch((e: any) =>
            console.error('[User Update] CoA disconnect error:', e.message)
          );
        } catch {}
      }
    }

    // Log activity
    try {
      const session = await getServerSession(authOptions);
      const changes: any = {};
      if (username !== user.username) changes.username = username;
      if (profileId !== user.profileId) changes.profileId = profileId;
      if (status !== user.status) changes.status = status;
      
      await logActivity({
        userId: (session?.user as any)?.id,
        username: (session?.user as any)?.username || 'Admin',
        userRole: (session?.user as any)?.role,
        action: 'UPDATE_PPPOE_USER',
        description: `Updated PPPoE user: ${username || user.username}`,
        module: 'pppoe',
        status: 'success',
        request,
        metadata: {
          userId: id,
          changes,
        },
      });
    } catch (logError) {
      console.error('Activity log error:', logError);
    }

    return NextResponse.json({ success: true, user });
  } catch (error) {
    console.error('Update PPPoE user error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE - Remove PPPoE user
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {
      return NextResponse.json({ error: 'User ID is required' }, { status: 400 });
    }

    const user = await prisma.pppoeUser.findUnique({ where: { id } });
    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Delete RADIUS entries
    try {
      await prisma.radcheck.deleteMany({
        where: { username: user.username },
      });
      await prisma.radreply.deleteMany({
        where: { username: user.username },
      });
      await prisma.radusergroup.deleteMany({
        where: { username: user.username },
      });
    } catch (syncError) {
      console.error('RADIUS cleanup error:', syncError);
    }

    // Delete user
    await prisma.pppoeUser.delete({ where: { id } });

    // Log activity
    try {
      const session = await getServerSession(authOptions);
      await logActivity({
        userId: (session?.user as any)?.id,
        username: (session?.user as any)?.username || 'Admin',
        userRole: (session?.user as any)?.role,
        action: 'DELETE_PPPOE_USER',
        description: `Deleted PPPoE user: ${user.username}`,
        module: 'pppoe',
        status: 'success',
        request,
        metadata: {
          userId: id,
          username: user.username,
        },
      });
    } catch (logError) {
      console.error('Activity log error:', logError);
    }

    return NextResponse.json({
      success: true,
      message: 'User deleted successfully',
    });
  } catch (error) {
    console.error('Delete PPPoE user error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
