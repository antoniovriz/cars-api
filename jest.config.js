export default {
  testEnvironment: 'node', // Use Node.js environment for Express tests
  transform: {}, // Disable Babel transform for ES modules
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1', // Remove .js extensions in imports
  },
};
