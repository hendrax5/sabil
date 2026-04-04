import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

// GET - Get single user with password
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;

    const user = await prisma.pppoeUser.findUnique({
      where: { id },
      include: {
        profile: true,
        router: true,
        area: { select: { id: true, name: true } },
      },
    });

    // Active session from radacct
    let activeSession = null;
    if (user) {
      activeSession = await prisma.radacct.findFirst({
        where: { username: user.username, acctstoptime: null },
        orderBy: { acctstarttime: 'desc' },
        select: {
          radacctid: true,
          acctstarttime: true,
          framedipaddress: true,
          nasipaddress: true,
          callingstationid: true,
          acctinputoctets: true,
          acctoutputoctets: true,
          acctsessiontime: true,
        },
      });
    }

    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    return NextResponse.json({ user, activeSession });
  } catch (error) {
    console.error('Get user error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
