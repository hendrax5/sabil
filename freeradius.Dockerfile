FROM freeradius/freeradius-server:3.2.3-alpine

# Copy the custom configuration over the Alpine default template
COPY ./salfanet-radius/freeradius-config/clients.conf /etc/raddb/clients.conf
COPY ./salfanet-radius/freeradius-config/mods-available/sql /etc/raddb/mods-available/sql
COPY ./salfanet-radius/freeradius-config/sites-available/default /etc/raddb/sites-available/default
COPY ./salfanet-radius/freeradius-config/clients.d /etc/raddb/clients.d

# Define variables available during build
ARG DB_HOST
ARG DB_USER
ARG DB_PASS
ARG DB_NAME

# Inject variables strictly into sql connector (Replacing template placeholders)
RUN sed -i "s/__DB_HOST__/${DB_HOST}/g" /etc/raddb/mods-available/sql && \
    sed -i "s/__DB_USER__/${DB_USER}/g" /etc/raddb/mods-available/sql && \
    sed -i "s/__DB_PASS__/${DB_PASS}/g" /etc/raddb/mods-available/sql && \
    sed -i "s/__DB_NAME__/${DB_NAME}/g" /etc/raddb/mods-available/sql

# Ensure the sql module is actively enabled
RUN ln -sf /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql

# Fix permissions globally so the internal radius user can read the files, avoiding unknown group errors
RUN chmod -R a+r /etc/raddb/clients.conf /etc/raddb/mods-available/sql /etc/raddb/sites-available/default
RUN chmod a+rx /etc/raddb/clients.d && chmod a+r /etc/raddb/clients.d/* || true

EXPOSE 1812/udp 1813/udp 3799/udp
