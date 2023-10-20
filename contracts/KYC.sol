// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
    enum Military_status {
        // could ignore and rely on roles only
        Non, // uint256 0 -> non
        Done,
        In
    }

    struct Person {
        uint256 NID; // check if could remove
        string fName;
        string lName;
        string fullName; // to 4th
        address payable person_wallet_address; // added manually by admins and editors?
        bytes avatar; // verify idententy
        bytes image_id;
        uint license_number;
        bytes license_image; // check valid with AI
        bytes[] certificates; // as images
        uint256 bod; // time stamp of birthdate
        Gender gender;
        Roles role; // in contract
        Permissions permission; // give permission for each field? , allow companies to take nessesary permissions to show filed
        string[] phone_number;
        string email; // an array?
        Login sign;
        string[] education;
        string[] experiance; // job and other like an CV
        string[] intrests;
        uint256[] bank_Accounts;
        uint256 father_id;
        uint256 mother_id;
        string home_address;
        string passport;
        Military_status ms;
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
    address payable public immutable i_owner;
    uint256[] private nationalIDs; // keys - prevent dublicate
    string[] private users; // users/admins list

    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

    // edit field log

    constructor(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id
    ) payable {
        i_owner = payable(msg.sender);
        // Init Deployer as Admin / Owner
        addPerson(_fname, _lname, _name, _id, Roles.Admin, msg.sender);
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
        // Check if the ID already exists
        require(people[_id].NID == 0, "ID already exists");

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
        if (_role == Roles.Admin) {
            person = hashLogInInfo(_id, "password", person);
            users[users.length] = Strings.toString(_id);
        }
        Permissions _permission = grantPermission(_role);
        person.permission = _permission;
        nationalIDs.push(_id); // prevent dublicate
        // Add the new person to the mapping
        people[_id] = person;
        emit AddPerson(_id, _name);
    }

    // admin init
    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        Roles _role,
        address _wallet
    ) public {
        require(_id > 0, "ID must be greater than zero");
        // Check if the ID already exists
        require(people[_id].NID == 0, "ID already exists");

        // Create a new Person instance
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name; // get fname , lname
        person.role = _role;
        // other fileds will be default values
        Permissions _permission = grantPermission(_role);
        person.permission = _permission;
        if (_role == Roles.Admin) {
            person = hashLogInInfo(_id, "password", person);
            users[users.length] = Strings.toString(_id);
        }
        person.person_wallet_address = payable(_wallet);
        nationalIDs.push(_id); // prevent dublicate
        // Add the new person to the mapping
        people[_id] = person;
        emit AddPerson(_id, _name);
    }

    // others
    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender
    ) public {
        // mandatory
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name; // get fname , lname
        person.bod = _bod;
        person.gender = _gender;
        person.role = Roles.Non; // defualt values for unmentioned
        // other fileds will be default values
        nationalIDs.push(_id); // prevent dublicate
        people[_id] = person;
        emit AddPerson(_id, _name);
    }

    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        address _wallet
    ) public {
        Person memory person;
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name;
        person.bod = _bod;
        person.gender = _gender;
        person.person_wallet_address = payable(_wallet);
        person.role = Roles.Non; // defualt
        nationalIDs.push(_id); // working with index
        people[_id] = person; // working with id
        emit AddPerson(_id, _name);
    }

    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        address _wallet,
        string[] memory mobile
    ) public {
        Person memory person;
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name;
        person.bod = _bod;
        person.gender = _gender;
        person.person_wallet_address = payable(_wallet); // not msg.sender
        person.phone_number = mobile;
        person.role = Roles.Non; // defualt
        nationalIDs.push(_id); // working with index
        people[_id] = person; // working with id
        emit AddPerson(_id, _name);
    }

    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        address _wallet,
        string[] memory mobile,
        uint256 licence
    ) public {
        Person memory person;
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name;
        person.bod = _bod;
        person.gender = _gender;
        person.person_wallet_address = payable(_wallet); // not msg.sender
        person.phone_number = mobile;
        person.license_number = licence;
        person.role = Roles.Non; // defualt
        nationalIDs.push(_id); // working with index
        people[_id] = person; // working with id
        emit AddPerson(_id, _name);
    }

    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        address _wallet,
        string[] memory mobile,
        uint256 licence,
        string memory _address
    ) public {
        Person memory person;
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name;
        person.bod = _bod;
        person.gender = _gender;
        person.person_wallet_address = payable(_wallet); // not msg.sender
        person.phone_number = mobile;
        person.license_number = licence;
        person.home_address = _address;
        person.role = Roles.Non; // defualt
        nationalIDs.push(_id); // working with index
        people[_id] = person; // working with id
        emit AddPerson(_id, _name);
    }

    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        address _wallet,
        string[] memory mobile,
        uint256 licence,
        string memory _address,
        uint256 fid,
        uint256 mid
    ) public {
        Person memory person;
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name;
        person.bod = _bod;
        person.gender = _gender;
        person.person_wallet_address = payable(_wallet); // not msg.sender
        person.phone_number = mobile;
        person.license_number = licence;
        person.home_address = _address;
        person.father_id = fid;
        person.mother_id = mid;
        person.role = Roles.Non; // defualt
        nationalIDs.push(_id); // working with index
        people[_id] = person; // working with id
        emit AddPerson(_id, _name);
    }

    // 2.

    //**  3. update and add data */
    function addEdu(uint id, string memory _education) public {
        //Person p = people[id];
        // p.education.push(_education);
        people[id].education.push(_education);
    }

    function addExp(uint id, string memory _experiance) public {
        people[id].experiance.push(_experiance);
    }

    function addMob(uint id, string memory _mobile) public {
        people[id].phone_number.push(_mobile);
    }

    function addBankAccount(uint id, uint256 _bank_Accounts) public {
        people[id].bank_Accounts.push(_bank_Accounts);
    }

    function addCertificate(uint id, bytes memory _certificate) public {
        people[id].certificates.push(_certificate);
    }

    function addIntrest(uint id, string memory _interest) public {
        people[id].intrests.push(_interest);
    }

    function updateLogin(uint id, bytes32 _hash) public {
        signIn[id] = _hash;
    }

    function EditLogin(
        uint _id,
        string memory _user,
        string memory _password,
        string memory _email
    ) public {
        if (isValidUser(_user) == true) {
            people[_id].sign.UserName = _user;
            users[users.length] = _user;
        }
        people[_id].sign.Password = _password;
        people[_id].sign.Email = _email;

        hashLogInInfo(_id, _user, _password);
    }

    function EditLogin(
        uint _id,
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
        for (uint i = 0; i < users.length; i++) {
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
    ) public view returns (bool) {
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
        string memory tohashed = concatenateStings(user, pass);
        bytes32 _hash = hashDataSHA(tohashed);
        signIn[_id] = _hash;
    }

    function hashLogInInfo(
        uint256 _id,
        string memory user,
        string memory pass,
        Person memory person
    ) private returns (Person memory) {
        string memory tohashed = concatenateStings(user, pass);
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
        string memory tohashed = concatenateStings(user, pass);
        bytes32 _hash = hashDataSHA(tohashed);
        signIn[_id] = _hash; // updateLogin hashing
        person.sign.UserName = user;
        person.sign.Password = pass;
        return person;
    }

    // hashing function
    function hashData(string memory data) public view returns (bytes32) {
        bytes32 hash = keccak256(bytes(data));
        return hash;
    }

    function hashDataSHA(string memory data) public view returns (bytes32) {
        bytes32 hash = sha256(bytes(data));
        return hash;
    }

    // valid from V 0.8.12 concat
    function concatenateStings(
        string memory a,
        string memory b
    ) public view returns (string memory) {
        return string.concat(a, b);
    }

    //**  view / pure functions (getters) */
    function getPerson(uint id) public view returns (Person memory) {
        return people[id];
    }

    function getNumberOfPersons() public view returns (uint256) {
        return nationalIDs.length;
    }

    function getNumberOfUsers() public view returns (uint256) {
        return users.length;
    }

    function getLogin(uint id) public view returns (bytes32) {
        return signIn[id]; // compare hash with hashed login in the backend
    }
}
