// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// errors
error KYC__NOT_Have_Access();
error Already_Exist();
error ID_must_be_greater_than_zero();

/**@title KYC Contract
 * @author Abdalrhman Mostafa and Ahmed Hesham
 * @notice This contract is for adding and retriving customers data
 */

contract KYC is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Types declartion
    // when add role, call function that add sutable permisson assigned to the rule
    enum Gender {
        Male, // 0
        Female // 1
    }
    enum Roles {
        Admin, // owner could add admins and other roles , full control
        User
    }
    // when do operations check and if not revert
    enum Permissions {
        // could ignore and rely on roles only
        Non,
        Full // Delete and RW
    }
    enum Military_status {
        // could ignore and rely on roles only
        Non, // uint256 0 -> non
        Done,
        In
    }

    struct Person {
        uint256 NID; // check if could remove
        string fullName; // to 4th
        address person_wallet_address; // added manually by admins and editors?
        uint256 bod; // time stamp of birthdate
        string job;
        Gender gender;
        Roles role; // in contract
        Permissions permission; // give permission for each field? , allow companies to take nessesary permissions to show filed
        string phone_number;
        Additional_Info info;
        Education edu;
    }

    struct Additional_Info {
        uint256 license_number;
        string image; // store hash verify idententy
        uint256[] bank_Accounts;
        string home_address;
        string passport;
        Military_status ms;
    }
    struct Education {
        uint256 year;
        string specialization;
        string place;
        string degree;
    }

    // storage vs memory
    mapping(uint256 => Person) internal people; // link person to his id
    mapping(uint256 => bytes32) internal signIn; // id -> hashed login info

    // State Variables
    uint256[] private nationalIDs; // keys - prevent dublicate
    uint256[] private users; // users/admins list

    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

    // edit field log

    function initialize(uint256 _id) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        addPerson(_id, msg.sender, "");
        //_disableInitializers();
    }

    function _authorizeUpgrade(
        address /*newImplementation*/
    ) internal view override {
        if (msg.sender != owner()) revert KYC__NOT_Have_Access();
    }

    //Resteriction
    function OnlyAdmin(uint256 id) internal view {
        Roles role = people[id].role;
        if (role != Roles.Admin) {
            revert KYC__NOT_Have_Access();
        }
    }

    // functions:
    //**  1. Add overloading Person */
    function addPerson(
        uint256 cid,
        string memory _name,
        uint256 _id,
        string memory _job,
        uint256 _bod,
        Gender _gender,
        Roles _role,
        string memory img
    ) public {
        OnlyAdmin(cid);
        if (_id < 0) {
            revert ID_must_be_greater_than_zero();
        }
        // Check if the ID already exists
        // require(people[_id].NID == _id, "ID already exists");
        if (people[_id].NID == _id) {
            revert Already_Exist();
        }
        // Create a new Person instance
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.fullName = _name; // get fname , lname
        person.job = _job;
        person.bod = _bod;
        person.gender = _gender;
        person.role = _role;
        // other fileds will be default values
        if (_role == Roles.Admin) {
            // Admins only could access (for now)
            person = hashLogInInfo(_id, Strings.toString(_id), person);
            // users[users.length] = Strings.toString(_id);
            users.push(_id);
        }

        Permissions _permission = grantPermission(_role);
        person.permission = _permission;
        nationalIDs.push(_id); // prevent dublicate
        person.info.image = img;
        // Add the new person to the mapping
        people[_id] = person;
        emit AddPerson(_id, _name);
    }

    // admin init (only owner)
    function addPerson(
        uint256 _id,
        address _wallet,
        string memory img
    ) internal {
        if (_id < 0) {
            revert ID_must_be_greater_than_zero();
        }

        // Create a new Person instance
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.role = Roles.Admin;
        // other fileds will be default values
        Permissions _permission = grantPermission(Roles.Admin);
        person.permission = _permission;
        person = hashLogInInfo(_id, "password", person);
        users.push(_id);
        person.info.image = img;
        person.person_wallet_address = _wallet;
        nationalIDs.push(_id); // prevent dublicate
        // Add the new person to the mapping
        people[_id] = person;
        emit AddPerson(_id, "Admin"); // events
    }

    // Edit Data Functions (for each edit there is gas consumption , we need to reduce the gas consumption)

    //** 3. Modify info. Functions */
    function editName(uint256 cid, uint256 _id, string memory name) public {
        OnlyAdmin(cid);
        people[_id].fullName = name;
    }

    function editWallet(
        uint256 cid,
        uint256 _id,
        address wallet_address
    ) public {
        OnlyAdmin(cid);
        people[_id].person_wallet_address = wallet_address;
    }

    function birthOfDate(uint256 cid, uint256 _id, uint256 bod) public {
        OnlyAdmin(cid);
        people[_id].bod = bod;
    }

    function editGender(uint256 cid, uint256 _id, uint8 gender) public {
        OnlyAdmin(cid);
        people[_id].gender = Gender(gender);
    }

    function editJob(uint256 cid, uint256 _id, string memory _job) public {
        OnlyAdmin(cid);
        people[_id].job = _job;
    }

    function editRole(uint256 cid, uint256 _id, uint8 role) public {
        OnlyAdmin(cid);
        if (role == 1 &&  people[_id].role == Roles(0) ) {
            removeIdFromArray(users, _id);
        }
        else if (role == 0 &&  people[_id].role == Roles(1) ) {
            users.push(_id);
        }
        people[_id].role = Roles(role);
        Permissions _permission = grantPermission(Roles(role));
        people[_id].permission = _permission;
    }

    function EditPhone(uint256 cid, uint256 _id, string memory phone) public {
        OnlyAdmin(cid);
        people[_id].phone_number = phone;
    }

    // Additional Info Functions
    function setImage(uint256 cid, uint256 id, string memory img) public {
        OnlyAdmin(cid);
        people[id].info.image = img;
    }

    function editEducation(
        uint256 cid,
        uint256 id,
        uint256 year,
        string memory specialization,
        string memory place,
        string memory degree
    ) public {
        OnlyAdmin(cid);
        people[id].edu.specialization = specialization;
        people[id].edu.place = place;
        people[id].edu.degree = degree;
        people[id].edu.year = year;
    }

    function deleteEducation(uint256 cid, uint256 id) public {
        OnlyAdmin(cid);
        delete people[id].edu;
    }

    function editLicenceNumber(
        uint256 cid,
        uint256 _id,
        uint256 license_number
    ) public {
        OnlyAdmin(cid);
        people[_id].info.license_number = license_number;
    }

    function editBankAccount(
        uint256 cid,
        uint256 _id,
        uint256 bank_Accounts
    ) public {
        OnlyAdmin(cid);
        people[_id].info.bank_Accounts.push(bank_Accounts);
    }

    function editAddress(
        uint256 cid,
        uint256 _id,
        string memory _address
    ) public {
        OnlyAdmin(cid);
        people[_id].info.home_address = _address;
    }

    function editPassport(
        uint256 cid,
        uint256 _id,
        string memory passport
    ) public {
        OnlyAdmin(cid);
        people[_id].info.passport = passport;
    }

    function editMilitaryStatus(uint256 cid, uint256 _id, uint256 ms) public {
        OnlyAdmin(cid);
        people[_id].info.ms = Military_status(ms);
    }

    function deletePerson(uint256 cid, uint256 _id) public {
        OnlyAdmin(cid);
        removeIdFromArray(nationalIDs, _id);
        if (people[_id].role == Roles.Admin) {
            removeIdFromArray(users, _id);
        }
        delete people[_id];
    }

    function removeIdFromArray(uint256[] storage array, uint256 _id) internal {
        uint256 index = findIndex(array, _id);
        if (index < array.length) {
            array[index] = array[array.length - 1];
            array.pop();
        }
    }

    function findIndex(
        uint256[] storage array,
        uint256 _id
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == _id) {
                return i;
            }
        }
        return array.length; // Return an out-of-bound index if not found
    }

    function EditLogin(uint256 _id, string memory _password) public {
        if (people[_id].role != Roles.Admin) {
            revert KYC__NOT_Have_Access();
        }
        hashLogInInfo(_id, _password);
    }

    function logIN(
        uint256 _id,
        string memory pass
    ) public view returns (bool, string memory, uint256) {
        if (
            hashDataSHA(string.concat(Strings.toString(_id), pass)).length !=
            signIn[_id].length
        ) {
            return (false, people[_id].info.image, _id);
        }
        //getPerson(_id);
        return (
            keccak256(abi.encodePacked(signIn[_id])) ==
                keccak256(
                    abi.encodePacked(
                        hashDataSHA(string.concat(Strings.toString(_id), pass))
                    )
                ),
            people[_id].info.image,
            _id
        );
    }

    function hashLogInInfo(uint256 _id, string memory pass) internal {
        signIn[_id] = hashDataSHA(string.concat(Strings.toString(_id), pass));
    }

    // init hashing login
    function hashLogInInfo(
        uint256 _id,
        string memory pass,
        Person memory person
    ) internal returns (Person memory) {
        bytes32 _hash = hashDataSHA(string.concat(Strings.toString(_id), pass));
        signIn[_id] = _hash; // updateLogin hashing
        return person;
    }

    //**  middle functions */
    function grantPermission(Roles _role) internal pure returns (Permissions) {
        if (_role == Roles.Admin) {
            return Permissions.Full;
        } else {
            return Permissions.Non;
        }
    }

    function hashDataSHA(string memory data) public pure returns (bytes32) {
        bytes32 hash = sha256(bytes(data));
        return hash;
    }

    //**  view / pure functions (getters) */
    function getPerson(uint256 id) public view returns (Person memory, bool) {
        if (people[id].NID == 0) {
            return (people[id], false);
        }
        return (people[id], true);
    }

    function getUser(uint256 index) public view returns (uint256) {
        return users[index];
    }

    function getNumberOfPersons() public view returns (uint256) {
        return nationalIDs.length;
    }

    function getNumberOfAdmins() public view returns (uint256) {
        return users.length;
    }

    function getLogin(uint256 id) public view returns (bytes32) {
        return signIn[id]; // compare hash with hashed login in the backend
    }

    function getImage(uint256 id) public view returns (string memory) {
        return people[id].info.image;
    }
}
