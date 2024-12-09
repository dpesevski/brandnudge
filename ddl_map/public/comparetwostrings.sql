CREATE FUNCTION comparetwostrings(title1 text, title2 text) RETURNS double precision
    LANGUAGE plv8
AS
$$

    const first = title1 ? title1.replace(/\s+/g, ''):'';
    const second = title2 ? title2.replace(/\s+/g, ''):'';

    if (!first.length && !second.length) return 1;
    if (!first.length || !second.length) return 0;
    if (first === second) return 1;
    if (first.length === 1 && second.length === 1) return 0;
    if (first.length < 2 || second.length < 2) return 0;

    const firstBigrams = new Map();
    for (let i = 0; i < first.length - 1; i += 1) {
      const bigram = first.substr(i, 2);
      const count = firstBigrams.has(bigram) ? firstBigrams.get(bigram) + 1 : 1;

      firstBigrams.set(bigram, count);
    }
    let intersectionSize = 0;
    for (let i = 0; i < second.length - 1; i += 1) {
      const bigram = second.substr(i, 2);
      const count = firstBigrams.has(bigram) ? firstBigrams.get(bigram) : 0;

      if (count > 0) {
        firstBigrams.set(bigram, count - 1);
        intersectionSize += 1;
      }
    }
    return (2.0 * intersectionSize) / (first.length + second.length - 2);
$$;

ALTER FUNCTION comparetwostrings(text, text) OWNER TO postgres;

