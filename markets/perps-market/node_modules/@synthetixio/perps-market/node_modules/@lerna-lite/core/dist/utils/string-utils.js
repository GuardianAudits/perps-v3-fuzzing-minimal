export function pluralize(str, strLn, customPluralStr = '') {
    const pluralStr = customPluralStr || `${str}s`;
    return strLn > 1 ? pluralStr : str;
}
export function excludeValuesFromArray(inputValues, excludeValues) {
    const checker = (value) => !excludeValues.some((element) => value === element);
    return inputValues.filter(checker);
}
//# sourceMappingURL=string-utils.js.map