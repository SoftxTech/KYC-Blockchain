// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;
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
    mapping(uint256 => bytes32) public signIn; // hashed login info

    // State Variables
    address payable public immutable i_owner;
    uint256[] private nationalIDs; // keys - prevent dublicate
    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

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

    // functions:
    // 1. Add overloading Person
    // TODO : if admin , init hash, normal user later.
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
        person = grantPermission(person);
        nationalIDs.push(_id); // prevent dublicate
        people[_id] = person;
        emit AddPerson(_id, _name);
    }

    // Mandatory -> Email?
    function addPerson(
        string memory _fname,
        string memory _lname,
        string memory _name,
        uint256 _id,
        uint256 _bod,
        Gender _gender,
        Roles _role
    ) public {
        // mandatory
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
            string memory user = concatenateStings(_fname, _lname);
            string memory pass = "password";
            string memory tohashed = concatenateStings(user, pass);
            bytes32 _hash = hashDataSHA(tohashed);
            signIn[_id] = _hash;
            person.sign.UserName = user;
            person.sign.Password = pass;
        }
        person = grantPermission(person);
        nationalIDs.push(_id); // prevent dublicate
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
        Person memory person; //Person(_id, _name,..,) | Person params = Person({a: 1, b: 2});
        person.NID = _id;
        person.fName = _fname;
        person.lName = _lname;
        person.fullName = _name; // get fname , lname
        person.role = _role;
        // other fileds will be default values
        person = grantPermission(person);
        if (_role == Roles.Admin) {
            string memory user = concatenateStings(_fname, _lname);
            string memory pass = "password";
            string memory tohashed = concatenateStings(user, pass);
            bytes32 _hash = hashDataSHA(tohashed);
            signIn[_id] = _hash;
            person.sign.UserName = user;
            person.sign.Password = pass;
        }
        person.person_wallet_address = payable(_wallet);
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
        person = grantPermission(person);
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

    // 3. update and add data
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
        uint id,
        string memory _user,
        string memory _password,
        string memory _email
    ) public {
        people[id].sign.UserName = _user;
        people[id].sign.Password = _password;
        people[id].sign.Email = _email;
    }

    // middle functions
    function grantPermission(
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

    function hashData(string memory data) public pure returns (bytes32) {
        bytes32 hash = keccak256(bytes(data));
        return hash;
    }

    function hashDataSHA(string memory data) public pure returns (bytes32) {
        bytes32 hash = sha256(bytes(data));
        return hash;
    }

    // valid from V 0.8.12
    function concatenateStings(
        string memory a,
        string memory b
    ) public pure returns (string memory) {
        return string.concat(a, b);
    }

    /*
    function searchField(address fieldValue) external view returns (uint256) {
        for (uint256 i = 0; i < nationalIDs.length; i++) {
            uint256 key = nationalIDs[i];
            Person memory person = people[key];
            if (person.person_wallet_address == fieldValue) {
                return person.NID;
            }
        }

        return 0;
    }
    */

    // view / pure functions (getters)
    function getPerson(uint id) public view returns (Person memory) {
        return people[id];
    }

    function getNumberOfPersons() public view returns (uint256) {
        return nationalIDs.length;
    }

    function getLogin(uint id) public view returns (bytes32) {
        return signIn[id]; // compare hash with hashed login in the backend
    }
}
