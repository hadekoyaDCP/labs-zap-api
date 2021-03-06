const carto = require('../utils/carto');

function getBblFeatureCollection(bbls) {
  let mutatedBBLs = bbls;
  if (mutatedBBLs === null) return null;

  mutatedBBLs = mutatedBBLs.filter(bbl => bbl !== null);

  const SQL = `
    SELECT the_geom
    FROM mappluto_v1711
    WHERE bbl IN (${mutatedBBLs.join(',')})
  `;

  return carto.SQL(SQL, 'geojson', 'post');
}

module.exports = getBblFeatureCollection;
