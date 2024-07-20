export function getPackagesForOption(option) {
    let inputs = null;
    if (option === true) {
        inputs = ['*'];
    }
    else if (typeof option === 'string') {
        inputs = option.split(',');
    }
    else if (Array.isArray(option)) {
        inputs = [...option];
    }
    return new Set(inputs);
}
//# sourceMappingURL=get-packages-for-option.js.map