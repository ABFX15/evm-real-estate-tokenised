// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Property} from "./Property.sol";

/**
 * @title AddProperty
 * @author Adam B Group 4
 * @notice Contract for listing and managing real estate properties as tokens
 * @dev Handles property listing, investment tracking, and tokenization status
 */
contract AddProperty {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AddProperty__NotOwner();
    error AddProperty__PropertyAlreadyExists();
    error AddProperty__InvalidAddress();
    error AddProperty__UserAlreadyExists();
    error AddProperty__NotUser();

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public s_owner;
    uint256 public s_propertyId;
    Property public property;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    struct AddingProperty {
        address propertyAddress;
        uint256 tokenId;
        uint256 amount;
        string popertyURI;
    }

    AddingProperty[] public properties;
    address[] public propertyOwnersList;
    address[] public users;

    mapping(uint256 => address) public propertyAddress; // propertyId to owner address
    mapping(address => uint256) public investorShares;    // investor => amount invested
    mapping(uint256 => mapping(address => uint256)) public propertyInvestments;    // propertyId => (investor => amount)
    mapping(uint256 => PropertyStatus) public propertyStatus;
    mapping(address => bool) public isUser;

    /// @dev In Solidity, when you access a mapping with a key that hasn't been set,
    /// it returns the default value for the value type. For an enum, the default value
    /// is the first defined enum value (index 0).
    /// So, we're adding an initial state value to overcome this issue.
    enum PropertyStatus {
        NotListed,  // Default state
        Listed,
        FullyFunded,
        Tokenized
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event PropertyAdded(
        uint256 indexed propertyId,
        address indexed owner,
        address indexed propertyAddress,
        uint256 tokenId,
        uint256 amount,
        string propertyURI
    );

    /// @dev Emitted when `user` is added to `propertyId`.
    event UserAdded(uint256 indexed propertyId, address indexed user);

    constructor(address _owner, uint256 _propertyId, address _property) {
        s_owner = _owner;
        s_propertyId = _propertyId;
        property = Property(_property);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyUser() {
        if(!isUser[msg.sender]) revert AddProperty__NotUser();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Adds a user to the list of users
     * @param _user The address of the user
     */
    function addUser(address _user) external {
        if(msg.sender != s_owner) revert AddProperty__NotOwner();
        if(isUser[_user]) revert AddProperty__UserAlreadyExists();
        users.push(_user);
        isUser[_user] = true;
        emit UserAdded(s_propertyId, _user);
    }

    /**
 * @notice Adds a property to the listing for users to invest in
 * an NFT is minted to the property owner to fractionalize
 * @param _propertyAddress The address of the property
 * @param _tokenId The tokenId of the property
 * @param _amount The amount of the property
 * @param _nftAmount The amount of NFTs to mint to the property owner
 * @param _propertyURI The URI of the property metadata
 */
    function addPropertyToListing(
        address _propertyAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _nftAmount,
        string memory _propertyURI
    ) external onlyUser {
        // input validation
        if(propertyStatus[_tokenId] != PropertyStatus.NotListed) revert AddProperty__PropertyAlreadyExists();
        if(_propertyAddress == address(0)) revert AddProperty__InvalidAddress();

        // increment before use to avoid starting at 0
        s_propertyId++;

        // create and store property
        AddingProperty memory newProperty = AddingProperty(
            _propertyAddress,
            _tokenId,
            _amount,
            _propertyURI
        );
        properties.push(newProperty);

        // update status and ownership
        propertyStatus[_tokenId] = PropertyStatus.Listed;
        propertyAddress[s_propertyId] = msg.sender;
        propertyOwnersList.push(msg.sender);

        // Mint NFT
        property.mint(msg.sender, s_propertyId, _nftAmount, "");

        emit PropertyAdded(
            s_propertyId,
            msg.sender,
            _propertyAddress,
            _tokenId,
            _amount,
            _propertyURI
        );
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getPropertyOwners() external view returns (address[] memory) {
        return propertyOwnersList;
    }

    function getPropertyListings() external view returns (AddingProperty[] memory) {
        return properties;
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }
}
