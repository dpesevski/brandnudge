CREATE FUNCTION calculatemultibuyprice(description text, price double precision) RETURNS double precision
    LANGUAGE plv8
AS
$$
function textToNumber(str) {
  const numMap = {
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
  };

  return Object.keys(numMap).reduce(
    (res, text) => res.replace(new RegExp(text, 'gi'), numMap[text]),
    str,
  );
}

function numPrice(price) {
  if (!price) return 1;
  if (!isNaN(price)) return price;
  if (price.includes('£')) return parseFloat(price.split('£')[1]).toFixed(2);
  else if (price.includes('p'))
    return parseFloat(price.split('p')[0] / 100).toFixed(2);
  return price;
}
 if (!description || !price) return price;
    let result = price;
    const desc = textToNumber(description.replace(',', '').toLowerCase());

    const isFloat = n => Number(n) === n && n % 1 !== 0;

    const countAndPrice = desc.match(/£?(\d+(.\d{1,2})?|\d+\/\d+)p?/g);
    if (!countAndPrice || !countAndPrice.length) return price;

    const [count, discountPrice = '£1'] = countAndPrice;
    const dp = numPrice(discountPrice);
    let sum = price * count;

    // "3 for 2" match
    const forMatch = desc.match(/(\d+) for (\d+)/i);

    if (forMatch) {
      // eslint-disable-next-line no-unused-vars
      const [match, totalCount, forCount] = forMatch;
      sum = price * forCount;
      result = sum / totalCount;
    } else if (desc.includes('save')) {
      const isPercent = desc.includes('%');
      const halfPrice = desc.includes('half price');
      // eslint-disable-next-line no-nested-ternary
      const discount = isPercent ? (sum / 100) * dp : halfPrice ? sum / 2 : dp;
      result = (sum - discount) / count;
    } else if (desc.includes('price of')) {
      result = (price * dp) / count;
    } else if (desc.includes('free')) {
      const freeCount = dp > count ? 1 : +dp;
      result = sum / (+count + freeCount);
    } else if (desc.includes('half price')) {
      sum += (price / 2) * dp;
      result = sum / (+count + +dp);
    } else {
      result = Math.round((dp * 100.0) / count) / 100;
    }

    result = isFloat(result) ? result.toFixed(2) : result;

    return result.toString();
$$;

ALTER FUNCTION calculatemultibuyprice(text, double precision) OWNER TO postgres;

