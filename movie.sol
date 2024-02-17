// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProofOfMovie {
    using SafeMath for uint256;

    mapping(bytes32 => bool) private unsoldMovies;
    mapping(bytes32 => address) private soldMovies;
    mapping(bytes32 => uint256) private soldTimestamps;
    bytes32[] private soldMovieList;
    bytes32[] private unsoldMovieList;
    mapping(bytes32 => string) private movieTitles; // Added mapping for movie titles
    mapping(bytes32 => uint256) private moviePrices; // Added mapping for movie prices

    //---events---
    event MovieBought(
        address buyer,
        string movieTitle,
        bytes32 movieHash,
        uint256 price,
        address seller,
        uint256 timestamp
    );

    event ListUnsoldMovie(
        address indexed seller,
        string movieTitle,
        bytes32 movieHash,
        uint256 price
    );

    // Add a modifier to check if the caller is the owner of the movie
    // modifier onlyMovieOwner(bytes32 movieHash) {
    //     require(
    //         msg.sender == soldMovies[movieHash],
    //         "You are not the owner of this movie"
    //     );
    //     _;
    // }

    // Function to buy a movie
    function buyMovie(bytes32 movieHash) public payable {
        require(unsoldMovies[movieHash], "This movie is not listed for sale");
        uint256 price = moviePrices[movieHash];

        require(msg.value >= price, "Insufficient funds to buy this movie");

        // Transfer the payment to the seller
        payable(soldMovies[movieHash]).transfer(msg.value);

        // Update mappings to reflect the purchase
        soldMovies[movieHash] = msg.sender;
        soldTimestamps[movieHash] = block.timestamp;
        unsoldMovies[movieHash] = false;
        removeFromUnsoldMovies(movieHash); // Remove the movie from unsoldMovies
        soldMovieList.push(movieHash);

        // Emit the MovieBought event
        emit MovieBought(
            msg.sender,
            movieTitles[movieHash],
            movieHash,
            price,
            soldMovies[movieHash],
            block.timestamp
        );
    }

    // Function to list a movie for sale and generate a new movie address
    // Function to list a movie for sale and generate a new movie address
    function listMovieForSale(string memory movieTitle, uint256 priceInWei)
        public
    {
        // Generate a new movie address (hash) based on the title
        bytes32 movieHash = generateMovieAddress(movieTitle);

        // Check if the movie is not already sold
        require(!unsoldMovies[movieHash], "This movie has already been sold");

        // Add the movie to the unsoldMovies mapping
        unsoldMovies[movieHash] = true;
        unsoldMovieList.push(movieHash);
        movieTitles[movieHash] = movieTitle; // Store the movie title
        moviePrices[movieHash] = priceInWei; // Store the movie price in wei

        // Emit the ListUnsoldMovie event with movie name and price
        emit ListUnsoldMovie(msg.sender, movieTitle, movieHash, priceInWei);

        // Additional event to store movie name and price
        emit NameAdded(msg.sender, movieTitle, movieHash);
    }

    // Function to remove a movie from unsoldMovies
    function removeFromUnsoldMovies(bytes32 movieHash) private {
        for (uint256 i = 0; i < unsoldMovieList.length; i++) {
            if (unsoldMovieList[i] == movieHash) {
                // Remove the movie hash from the unsoldMovieList
                unsoldMovieList[i] = unsoldMovieList[
                    unsoldMovieList.length - 1
                ];
                unsoldMovieList.pop();
                break;
            }
        }
    }

    // Function to generate a new movie address (hash)
    function generateMovieAddress(string memory movieTitle)
        private
        pure
        returns (bytes32)
    {
        return sha256(bytes(movieTitle));
    }

    function getListOfSoldMovieInfo()
        public
        view
        returns (
            string[] memory titles,
            address[] memory owners,
            uint256[] memory timestamps
        )
    {
        uint256 numSoldMovies = soldMovieList.length;
        titles = new string[](numSoldMovies);
        owners = new address[](numSoldMovies);
        timestamps = new uint256[](numSoldMovies);

        for (uint256 i = 0; i < numSoldMovies; i++) {
            bytes32 movieHash = soldMovieList[i];
            (titles[i], owners[i], timestamps[i]) = getSoldMovieInfoWithTitles(
                movieHash
            );
        }

        return (titles, owners, timestamps);
    }

    function getListOfUnsoldMovieInfoWithTitles()
        public
        view
        returns (
            string[] memory titles,
            address[] memory sellers,
            uint256[] memory prices
        )
    {
        uint256 numUnsoldMovies = unsoldMovieList.length;
        titles = new string[](numUnsoldMovies);
        sellers = new address[](numUnsoldMovies);
        prices = new uint256[](numUnsoldMovies);

        for (uint256 i = 0; i < numUnsoldMovies; i++) {
            bytes32 movieHash = unsoldMovieList[i];
            titles[i] = movieTitles[movieHash];
            sellers[i] = soldMovies[movieHash];
            prices[i] = moviePrices[movieHash]; // Retrieve the stored movie price
        }

        return (titles, sellers, prices);
    }

    function buyMovieByTitle(string memory movieTitle) public payable {
        // Generate a movie hash based on the provided title
        bytes32 movieHash = generateMovieAddress(movieTitle);

        // Check if the movie is listed for sale
        require(unsoldMovies[movieHash], "This movie is not listed for sale");

        uint256 price = moviePrices[movieHash];

        // Check if the sent value is sufficient to buy the movie
        require(msg.value >= price, "Insufficient funds to buy this movie");

        // Transfer the payment to the seller
        payable(soldMovies[movieHash]).transfer(msg.value);

        // Update mappings to reflect the purchase
        soldMovies[movieHash] = msg.sender;
        soldTimestamps[movieHash] = block.timestamp;
        unsoldMovies[movieHash] = false;
        removeFromUnsoldMovies(movieHash); // Remove the movie from unsoldMovies
        soldMovieList.push(movieHash);

        // Emit the MovieBought event
        emit MovieBought(
            msg.sender,
            movieTitles[movieHash],
            movieHash,
            price, // Do not convert price to wei here
            soldMovies[movieHash],
            block.timestamp
        );
    }

    function getSoldMovieInfoWithTitles(bytes32 movieHash)
        public
        view
        returns (
            // onlyMovieOwner(movieHash)
            string memory title,
            address owner,
            uint256 timestamp
        )
    {
        return (
            movieTitles[movieHash],
            soldMovies[movieHash],
            soldTimestamps[movieHash]
        );
    }

    // Function to get information about a sold movie
    function getSoldMovieInfo(bytes32 movieHash)
        public
        view
        returns (
            // onlyMovieOwner(movieHash)
            address owner,
            uint256 timestamp
        )
    {
        return (soldMovies[movieHash], soldTimestamps[movieHash]);
    }

    // Function to get the list of sold movies
    function getListOfSoldMovies() public view returns (bytes32[] memory) {
        return soldMovieList;
    }

    // Function to get the list of unsold movies
    function getListOfUnsoldMovies() public view returns (bytes32[] memory) {
        return unsoldMovieList;
    }

    //---events---
    event NameAdded(address from, string text, bytes32 hash);

    event RegistrationError(address from, string text, string reason);

    // SHA256 for Integrity
    function hashing(string memory name) private pure returns (bytes32) {
        return sha256(bytes(name));
    }

    function checkName(string memory name) public view returns (bool) {
        return unsoldMovies[hashing(name)];
    }
}
