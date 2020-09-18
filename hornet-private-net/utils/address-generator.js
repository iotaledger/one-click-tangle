const Iota = require("@iota/core");

const seed = process.argv[2];

function generateAddress(seed) {
  // Connect to a node
  const iota = Iota.composeAPI( { } );

  // Define the security level of the address
  const securityLevel = 2;

  return iota.getNewAddress(seed, {
      index: 1,
      securityLevel,
      total: 1,
    });
}

generateAddress(seed).then((address) => console.log(address[0]), (error) => console.error(error));
