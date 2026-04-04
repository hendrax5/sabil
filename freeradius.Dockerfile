FROM freeradius/freeradius-server:3.2.3-alpine

# Copy the custom configuration over the Alpine default template
COPY ./salfanet-radius/freeradius-config/clients.conf /etc/raddb/clients.conf
COPY ./salfanet-radius/freeradius-config/mods-available/sql /etc/raddb/mods-available/sql
COPY ./salfanet-radius/freeradius-config/sites-available/default /etc/raddb/sites-available/default
COPY ./salfanet-radius/freeradius-config/clients.d /etc/raddb/clients.d

# Ensure the sql module is actively enabled
RUN ln -sf /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql

# Fix permissions so the internal radius user can read the files
RUN chown -R root:radius /etc/raddb && chmod -R 640 /etc/raddb/clients.conf /etc/raddb/mods-available/sql /etc/raddb/sites-available/default
RUN chmod 750 /etc/raddb/clients.d && chmod 640 /etc/raddb/clients.d/* || true

EXPOSE 1812/udp 1813/udp 3799/udp
