#!/usr/bin/env bash

###############################################################################
# geo-infra Scripts and templates to create and manage geoportals
# Copyright (c) 2015-2016, sigeom sa
# Copyright (c) 2015-2016, Ioda-Net Sàrl
#
# Contact : contact (at)  geoportal (dot) xyz
# Repository : https://github.com/ioda-net/geo-infra
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
###############################################################################
#
#  @Date   : 2015-06-05
#  @Author : Bruno Friedmann
#  @Copyright : ioda-net sarl - CH2947 Charmoille
#  @License : WTFPL
#
#  @description :
#    This explain how to recreate the postgis template on an empty postgresql server
#    If it exists, we can't drop it unless it's no more a template
#    Need to be run as root or user able to su to postgres user
#    template_postgis is used to create postgis ready database with a simple call
#	 it need to be upgraded when postgis is updated (whatever version change)
#    To check if the template is update to date 
#    psql -d template_postgis -c "select postgis_full_version()" 
#    and check if the need update remark is present
# 

su postgres -c "psql -d postgres -c \"UPDATE pg_database SET datistemplate = FALSE where datname = 'template_postgis';\""

su postgres -c 'psql -d postgres -c "DROP DATABASE template_postgis;"'

# If your template1 is not fr_CH use template0
su postgres -c "psql -d postgres -c \"
CREATE DATABASE template_postgis
  WITH ENCODING='UTF8'
       OWNER=postgres
       TEMPLATE=template1
       LC_COLLATE='fr_CH.UTF-8'
       LC_CTYPE='fr_CH.UTF-8'
       CONNECTION LIMIT=-1;
\""

su postgres -c "psql -d postgres -c \"
COMMENT ON DATABASE template_postgis
  IS 'postGIS database template
postGIS functions and data are stored in public (Postgis recommanded way)
Topology functions are stored in topology schema

Users data are stored in userdata schema, added to the search_path db var.
';

REVOKE ALL ON DATABASE template_postgis FROM public;
\""

su postgres -c 'psql -d template_postgis -c "ALTER DATABASE template_postgis SET search_path=public, topology, pg_catalog;"'

su postgres -c "psql -d template_postgis <<EOSQ2
CREATE LANGUAGE plpgsql;
ALTER LANGUAGE plpgsql OWNER TO postgres;
GRANT USAGE ON LANGUAGE plpgsql TO public;

CREATE SCHEMA userdata
  AUTHORIZATION postgres;

GRANT ALL ON SCHEMA userdata TO postgres;
GRANT USAGE ON SCHEMA userdata TO public;

COMMENT ON SCHEMA userdata IS 'Schema for storing userdata';

EOSQ2
"

# Create Postgis extension + topology_extension
su postgres -c "psql -d template_postgis <<EOE
create extension postgis;
create extension postgis_topology;
EOE
"

# Make it a template
su postgres -c "psql -d postgres -c \"UPDATE pg_database SET datistemplate = TRUE where datname = 'template_postgis';\""

# Make search path aware of our userdata schema
su postgres -c 'psql -c "ALTER DATABASE template_postgis SET search_path=userdata,public,topology, pg_catalog;"

'
