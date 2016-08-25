-- remove_accents function
CREATE OR REPLACE FUNCTION public.remove_accents(string character varying)
  RETURNS character varying AS
$BODY$
    DECLARE
        res varchar;
    BEGIN
        res := replace(string, 'ü', 'ue');
        res := replace(res, 'Ü', 'ue');
        res := replace(res, 'ä', 'ae');
        res := replace(res, 'Ä', 'ae');
        res := replace(res, 'ö', 'oe');
        res := replace(res, 'Ö', 'oe');
        res := replace(res, '(', '_');
        res := replace(res, ')', '_');
        res:= translate(res, 'àáâÀÁÂ', 'aaaaaa');
        res:= translate(res, 'èéêëÈÉÊË', 'eeeeeeee');
        res:= translate(res, 'ìíîïÌÍÎÏ', 'iiiiiiii');
        res:= translate(res, 'òóôÒÓÔ', 'oooooo');
        res:= translate(res, 'ùúûÙÚÛ', 'uuuuuu');
        res:= translate(res, 'ç', 'c');
        RETURN trim(lower(res));
    END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
-- end remove_accents function


-- quadindex function
CREATE OR REPLACE FUNCTION public.quadindex(geom geometry)
  RETURNS text AS
$BODY$
DECLARE
    x_min       double precision;
    y_max       double precision;
    width       double precision;
    height      double precision;
    quadindex   text;
    quadcurrent text;
    bbox    geometry;
    quadgeom    geometry;
    quadgeom_0  geometry;
    quadgeom_1  geometry;
    quadgeom_2  geometry;
    quadgeom_3  geometry;
    maxlevels   integer;

BEGIN
    x_min       := 420000::double precision;
    y_max       := 510000::double precision;
    width       := 480000::double precision;
    height      := 480000::double precision;
    maxlevels   := 20; -- resolution 0.45m
    quadindex   := '0'; -- origin quadindex node address default to 0

    /*
                   510000
          +-------+-------+
          |       |       |
          |       |       |
          |   0   |   1   |
          |       |       |
   420000 +-------+-------+ 900000
          |       |       |
          |       |       |
          |   2   |   3   |
          |       |       |
          +-------+-------+
                30000
    */

    FOR  i IN 1..maxlevels LOOP
        quadgeom = st_geometryfromtext('LINESTRING('||x_min||' '||y_max||','||(x_min+width)||' '||(y_max-height)||')',21781);
            IF  NOT geom @ quadgeom THEN
        EXIT;
        END IF;


        width := width/2;
        height:= height/2;
        quadgeom_0 = st_geometryfromtext('LINESTRING('||x_min||' '||y_max||','||(x_min+width)||' '||(y_max-height)||')',21781);
        quadgeom_1 = st_geometryfromtext('LINESTRING('||(x_min+width)||' '||y_max||','||(x_min+(2*width))||' '||(y_max-height)||')',21781);
        quadgeom_2 = st_geometryfromtext('LINESTRING('||x_min||' '||y_max-height||','||(x_min+width)||' '||(y_max-(2*height))||')',21781);
        quadgeom_3 = st_geometryfromtext('LINESTRING('||(x_min+width)||' '||(y_max-height)||','||(x_min+2*width)||' '||(y_max-(2*height))||')',21781);


        CASE
        WHEN geom @ quadgeom_0 THEN
            quadindex   := quadindex||'0';
        WHEN geom @ quadgeom_1 THEN
            x_min       := x_min+width;
            quadindex   := quadindex||'1';
        WHEN geom @ quadgeom_2 THEN
            y_max       := y_max-height;
            quadindex   := quadindex||'2';
        WHEN geom @ quadgeom_3 THEN
            x_min       := x_min+width;
            y_max       := y_max-height;
            quadindex   := quadindex||'3';
        ELSE
            EXIT;
         END CASE;
        i := i+1;
    END LOOP;
    return ( quadindex );
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
-- end quadindex function
