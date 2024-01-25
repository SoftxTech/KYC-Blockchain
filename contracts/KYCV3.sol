// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// error NOT_Enough_FEE;
error KYC__NOT_Have_Access();
error Already_Exist();

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
    enum Military_status {
        // could ignore and rely on roles only
        Non, // uint256 0 -> non
        Done,
        In
    }

    struct Person {
        uint256  NID; // check if could remove
        string fName;
        string lName;
        string fullName; // to 4th
        address  person_wallet_address; // added manually by admins and editors?
        uint256 bod; // time stamp of birthdate
        Gender gender;
        Roles role; // in contract
        Permissions permission; // give permission for each field? , allow companies to take nessesary permissions to show filed
        string[] phone_number;
        // string email; // an array?
        Login sign;
        Additional_Info info;
    }

    struct Additional_Info {
        uint256 license_number;
        //bytes license_image; // check valid with AI
        // bytes[] certificates; // as images
        //bytes avatar; // verify idententy
        //bytes image_id;
        Education education;
        Experiance experiance; // job and other like an CV
        string[] intrests;
        uint256[] bank_Accounts;
        uint256 father_id;
        uint256 mother_id;
        string home_address;
        string passport;
        Military_status ms;
    }
    struct Education{
        uint256 year;
        string specialization;
        string place;
    }
    struct Experiance{
        uint256 year;
        string specialization;
        string designation;
        string place;
    }
    struct Login {
        string UserName;
        string Password;
        string Email;
    }
    // storage vs memory
    mapping(uint256 => Person) public people; // link person to his id
    mapping(uint256 => bytes32) public signIn; // id -> hashed login info

    // State Variables
    address  public immutable i_owner;
    uint256[] private nationalIDs; // keys - prevent dublicate
    string[] private users; // users/admins list

    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

    // edit field log

    constructor(
        uint256 _id //TODO add other info
    )  {
        i_owner = msg.sender;
        // Init Deployer as Admin / Owner
       addPerson( _id, msg.sender);
    }

    modifier OnlyAdmin(uint256 id) {
        Roles role = people[id].role;
        if (role != Roles.Admin) {
            revert KYC__NOT_Have_Access();
        }
        _;
    }

    // functions:
    //**  1. Add overloading Person */
    // TODO : if admin , init hash, normal user later.
    // Mandatory -> Email?
    function addPerson(
        uint256 cid,
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        Roles _role
    ) public OnlyAdmin(cid) {
        require(_id > 0, "ID must be greater than zero");
        //TODO Check if the ID already exists
       // require(people[_id].NID == _id, "ID already exists");
        if (people[_id].NID == _id)
        {
            revert Already_Exist();
        }
        // Create a new Person instance
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name; // get fname , lname
        person.bod = _bod;
        person.gender = _gender;
        person.role = _role;
        // other fileds will be default values
        if (_role == Roles.Admin) { // Admins only could access (for now)
            person = hashLogInInfo(_id, "password", person);
            // users[users.length] = Strings.toString(_id);
            users.push(Strings.toString(_id));
        }
        Permissions _permission = grantPermission(_role);
        person.permission = _permission;
        nationalIDs.push(_id); // prevent dublicate
        // Add the new person to the mapping
        people[_id] = person;
        emit AddPerson(_id, _name);
    }

    // admin init (only owner)
    function addPerson (
        uint256 _id,
        address _wallet
    ) private {
         require(_id > 0, "ID must be greater than zero");
        // Check if the ID already exists
        //require(people[_id].NID == _id, "ID already exists");

        // Create a new Person instance
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.role = Roles.Admin;
        // other fileds will be default values
        Permissions _permission = grantPermission(Roles.Admin);
        person.permission = _permission;
        person = hashLogInInfo(_id, "password", person);
        users.push(Strings.toString(_id));
        person.person_wallet_address = _wallet;
        nationalIDs.push(_id); // prevent dublicate
        // Add the new person to the mapping
        people[_id] = person;
        emit AddPerson(_id, "Admin"); // events
    }

   
    function updateLogin(uint256 id, bytes32 _hash) public {
        signIn[id] = _hash;
    }

    function EditLogin(
        uint256 _id,
        string memory _user,
        string memory _password,
        string memory _email
    ) public {
        if (isValidUser(_user) == true) {
            people[_id].sign.UserName = _user;
            //users[users.length] = _user;
            users.push(_user);
        }
        people[_id].sign.Password = _password;
        people[_id].sign.Email = _email;

        hashLogInInfo(_id, _user, _password);
    }

    function EditLogin(
        uint256 _id,
        string memory _password,
        string memory _email
    ) public {
        people[_id].sign.Password = _password;
        people[_id].sign.Email = _email;
        string memory _user = people[_id].sign.UserName;
        hashLogInInfo(_id, _user, _password);
    }

    //**  middle functions */
    function grantPermission(Roles _role) private pure returns (Permissions) {
        if (_role == Roles.Non) {
            return Permissions.Non;
        } else if (_role == Roles.Admin) {
            return Permissions.Full;
        } else if (_role == Roles.Co_Admin) {
            return Permissions.RW;
        } else if (_role == Roles.Editor) {
            return Permissions.Write;
        } else {
            return Permissions.Read;
        }
    }

    // check if user not dublicate
    function isValidUser(string memory userName) private view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            string memory user = users[i];
            bool found = compare(userName, user);
            if (found) {
                return false;
            }
        }
        return true;
    }

    function compare(
        string memory str1,
        string memory str2
    ) private pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    // TODO hashing login known user , later Email / user
    function hashLogInInfo(
        uint256 _id,
        string memory user,
        string memory pass
    ) private {
        string memory tohashed = string.concat(user, pass);
        bytes32 _hash = hashDataSHA(tohashed);
        signIn[_id] = _hash;
    }

    function hashLogInInfo(
        uint256 _id,
        string memory user,
        string memory pass,
        Person memory person
    ) private returns (Person memory) {
        string memory tohashed = string.concat(user, pass);
        bytes32 _hash = hashDataSHA(tohashed);
        signIn[_id] = _hash;
        person.sign.UserName = user;
        person.sign.Password = pass;
        return person;
    }

    // init hashing login
    function hashLogInInfo(
        uint256 _id,
        string memory pass,
        Person memory person
    ) private returns (Person memory) {
        string memory user = Strings.toString(_id);
        string memory tohashed = string.concat(user, pass);
        // console.log(tohashed);
        console.log("sha");
        bytes32 _hash = hashDataSHA(tohashed);
        //console.logBytes32(_hash);
        // string memory reversedInput = string(abi.encodePacked(_hash));
        signIn[_id] = _hash; // updateLogin hashing
        //console.logBytes32(signIn[_id]);
        person.sign.UserName = user;
        person.sign.Password = pass;
        return person;
    }

    // hashing function
    function hashData(string memory data) public pure returns (bytes32) {
        bytes32 hash = keccak256(bytes(data));
        return hash;
    }

    function hashDataSHA(string memory data) public pure returns (bytes32) {
       // bytes memory sad = bytes(data);
        //console.logBytes(sad);
        bytes32 hash = sha256(bytes(data));
        //console.logBytes32(hash);
        return hash;
    }

    // valid from V 0.8.12 concat
    /*
    function concatenateStings(
        string memory a,
        string memory b
    ) public pure returns (string memory) {
        return string.concat(a, b);
    }
*/
    //**  view / pure functions (getters) */
    function getPerson(uint256 id) public view returns (Person memory) {
        return people[id];
    }
    function getUser(uint id) public view returns (string memory) {
        return users[id];
    }


    function getNumberOfPersons() public view returns (uint256) {
        return nationalIDs.length;
    }

    function getNumberOfUsers() public view returns (uint256) {
        return users.length;
    }

    function getLogin(uint256 id) public view returns (bytes32) {
        return signIn[id]; // compare hash with hashed login in the backend
    }
}
