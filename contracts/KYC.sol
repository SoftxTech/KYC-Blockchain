// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;
import "hardhat/console.sol";
// error NOT_Enough_FEE;
error KYC__NOT_Have_Access();

/**@title KYC Contract
 * @author Abdalrhman Mostafa
 * @notice This contract is for adding and retriving customers data
 */
//TODO use Proxy pattern Contract to save DB isolated
contract KYC {
    // Types declartion
    // when add role, call function that add sutable permisson assigned to the rule
    enum Gender {
        Male, // 0
        Female // 1
    }
    enum Roles {
        Non, // uint256 0 -> Non , default
        Viewer, // reads only
        Editor, // like a data enter
        Co_Admin, // rw
        Admin // owner could add admins and other roles , full control
    }
    // when do operations check and if not revert
    // require(person.name.length > 0, "Person must have a name");
    enum Permissions {
        // could ignore and rely on roles only
        Non,
        Read, // uint256 0 -> Read
        Write,
        RW,
        Full // Delete and RW
    }
    struct Person {
        uint256 NID; // check if could remove
        string fName;
        string lName;
        string fullName; // 4th
        address payable person_wallet_address; // added manually by admins and editors?
        bytes avatar;
        bytes image_id;
        uint license_number;
        bytes license_image; // check valid with AI
        bytes[] certificates; // as images
        uint256 bod; // time stamp of birthdate
        Gender gender;
        Roles role; // in contract
        Permissions permission;
        string[] phone_number;
        string[] education;
        string[] experiance; // job and other like an CV
        string[] intrests;
        uint256[] bank_Accounts;
        uint256 father_id;
        uint256 mother_id;
        string home_address;
        // add militry status
    }
    // storage vs memory
    mapping(uint256 => Person) public people; // link person to his id

    // State Variables
    address payable public immutable i_owner;
    Person[] private persons;
    uint public unlockTime;

    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        i_owner = payable(msg.sender);
    }

    // functions
    function addPerson(string memory _name, uint256 _id) public {
        // mandatory
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.fullName = _name;
        person.role = Roles.Non; // defualt
        // other fileds will be default values
        persons.push(person);
        people[_id] = person;
    }

    // overloading
    function addPerson(
        string memory _name,
        uint256 _id,
        address wallet
    ) public {
        Person memory person;
        person.NID = _id;
        person.fullName = _name;
        person.person_wallet_address = payable(wallet);
        person.role = Roles.Non; // defualt
        persons.push(person); // working with index
        people[_id] = person; // working with id
    }

    function givePermission(
        Person memory person
    ) private pure returns (Person memory) {
        if (person.role == Roles.Non) {
            person.permission = Permissions.Non;
        } else if (person.role == Roles.Admin) {
            person.permission = Permissions.Full;
        } else if (person.role == Roles.Co_Admin) {
            person.permission = Permissions.RW;
        } else if (person.role == Roles.Editor) {
            person.permission = Permissions.Write;
        } else person.permission = Permissions.Read;
        return person;
    }

    // view / pure functions (getters)
    function getPerson(uint id) public view returns (Person memory) {
        return people[id];
    }

    function getPersons(uint index) public view returns (Person memory) {
        return persons[index];
    }
}
