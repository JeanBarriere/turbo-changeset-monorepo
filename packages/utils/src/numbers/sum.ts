export const sum = (a: number, b: number): number => {
    if (!a || !b) {
        throw new Error('Invalid arguments');
    }
    if (typeof a !== 'number' || typeof b !== 'number') {
        throw new Error('a and b must be numbers');
    }

    return (a + b);
};
