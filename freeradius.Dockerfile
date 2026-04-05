FROM ubuntu:24.04

# Avoid tzdata interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install FreeRADIUS and exact same extensions originally used in VPS
RUN apt-get update && \
    apt-get install -y freeradius freeradius-mysql freeradius-utils freeradius-rest && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy configuration directly matching the pure Debian/Ubuntu installation paths
COPY ./salfanet-radius/freeradius-config/clients.conf /etc/freeradius/3.0/clients.conf
COPY ./salfanet-radius/freeradius-config/mods-available/sql /etc/freeradius/3.0/mods-available/sql
COPY ./salfanet-radius/freeradius-config/mods-available/rest /etc/freeradius/3.0/mods-available/rest
COPY ./salfanet-radius/freeradius-config/mods-available/mschap /etc/freeradius/3.0/mods-available/mschap
COPY ./salfanet-radius/freeradius-config/sites-available/default /etc/freeradius/3.0/sites-available/default
COPY ./salfanet-radius/freeradius-config/sites-available/coa /etc/freeradius/3.0/sites-available/coa
COPY ./salfanet-radius/freeradius-config/policy.d/filter /etc/freeradius/3.0/policy.d/filter
COPY ./salfanet-radius/freeradius-config/clients.d /etc/freeradius/3.0/clients.d

# Define variables available during build
ARG DB_HOST
ARG DB_USER
ARG DB_PASS
ARG DB_NAME

# Inject variables strictly into sql connector (Replacing template placeholders)
RUN sed -i "s/__DB_HOST__/${DB_HOST}/g" /etc/freeradius/3.0/mods-available/sql && \
    sed -i "s/__DB_USER__/${DB_USER}/g" /etc/freeradius/3.0/mods-available/sql && \
    sed -i "s/__DB_PASS__/${DB_PASS}/g" /etc/freeradius/3.0/mods-available/sql && \
    sed -i "s/__DB_NAME__/${DB_NAME}/g" /etc/freeradius/3.0/mods-available/sql

# Enable modules precisely mimicking VPS install scripts
RUN ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql && \
    ln -sf /etc/freeradius/3.0/mods-available/rest /etc/freeradius/3.0/mods-enabled/rest && \
    ln -sf /etc/freeradius/3.0/sites-available/coa /etc/freeradius/3.0/sites-enabled/coa

# Apply exact Debian/Ubuntu security permissions (freerad:freerad)
RUN chown -R freerad:freerad /etc/freeradius/3.0 && \
    chmod 640 /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/sites-available/default && \
    chmod 750 /etc/freeradius/3.0/clients.d || true

EXPOSE 1812/udp 1813/udp 3799/udp

# Boot FreeRADIUS natively in foreground
CMD ["freeradius", "-f"]
