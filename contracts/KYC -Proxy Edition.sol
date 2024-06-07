// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// error NOT_Enough_FEE;
error KYC__NOT_Have_Access();
error Already_Exist();
error ID_must_be_greater_than_zero();

/**@title KYC Contract
 * @author Abdalrhman Mostafa
 * @notice This contract is for adding and retriving customers data
 */
//TODO use Proxy pattern Contract to save DB isolated
contract KYC is Initializable, OwnableUpgradeable, UUPSUpgradeable{
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
        string email; // an array?
        Login sign;
        Additional_Info info;
    }

    struct Additional_Info {
        uint256 license_number;
        //string license_image; // check valid with AI
        //string image; // store hash verify idententy
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
        string degree;
    }
    struct Experiance{
        uint256 year;
        string specialization;
        string designation;
        string place;
        //string[] certificates; // as images
        // add cv attachment (ipfs hash)
    }
    struct Login {
        string UserName;
        string Password;
        string Email;
    }
    // storage vs memory
    mapping(uint256 => Person) internal people; // link person to his id
    mapping(uint256 => bytes32) internal signIn; // id -> hashed login info
    mapping(uint256 => Education[]) internal education; // 
    mapping(uint256 => Experiance[]) internal experiance; // 

    // State Variables
    address public immutable i_owner;
    uint256[] private nationalIDs; // keys - prevent dublicate
    string[] private users; // users/admins list

    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

    // edit field log

    function initialize(uint256 _id) initializer public {
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
     addPerson( _id, msg.sender);
    _disableInitializers();
}

function _authorizeUpgrade(address newImplementation) internal onlyOwner override
{
    
}
    //TODO check token boolean if valid | get session of token info
    function  OnlyAdmin(uint256 id) private view {
        Roles role = people[id].role;
        //TODO check login
        if (role != Roles.Admin) {
            revert KYC__NOT_Have_Access();
        }
        //_;
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
    ) public  {
        OnlyAdmin(cid);
        //require(_id > 0, "ID must be greater than zero");
        if (_id<0)
        {
            revert ID_must_be_greater_than_zero();
        }
        // Check if the ID already exists
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
        //  require(_id > 0, "ID must be greater than zero");
        if (_id<0)
        {
            revert ID_must_be_greater_than_zero();
        }
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
    // Edit Data Functions (for each edit there is gas consumption , we need to reduce the gas consumption)

    //** 3. Modify info. Functions */
    function editWallet (uint cid, uint _id,address wallet_address) public 
    {
        OnlyAdmin(cid);
       // Person memory tmp = people[_id];
        people[_id].person_wallet_address = wallet_address;
       // people[_id] = tmp;
    }
    function birthOfDate (uint cid, uint _id,uint256 bod) public 
    {
        OnlyAdmin(cid);
        people[_id].bod = bod;
    }
    function editGender (uint cid, uint _id,uint8 gender) public
    {
        OnlyAdmin(cid);
        people[_id].gender = Gender(gender);
    }
    function editRole (uint cid, uint _id,uint8 role) public
    {
        OnlyAdmin(cid);
        people[_id].role = Roles(role);
        //TODO change Permissions
    }
    function editEmail (uint cid, uint _id,string memory email) public 
    {
        OnlyAdmin(cid);
        people[_id].email = email;
    }
    function EditPhone (uint cid, uint _id,string memory phone) public 
    {
        OnlyAdmin(cid);
        // TODO if want to remove phone number
        people[_id].phone_number.push(phone);
    }
    // Additional Info Functions

    // Education 
    function addEducation(uint cid, uint id,uint256 year,
        string memory specialization,
        string memory place,
        string memory degree) public 
    {
        OnlyAdmin(cid);
        Education[] storage tmp = education[id];
        Education memory edu;
        edu.degree = degree;
        edu.place = place;
        edu.specialization = specialization;
        edu.year = year;
        tmp.push(edu);
        education[id] = tmp;
    }
    // TODO if remove index
    function editEducation(uint cid,uint256 id,uint i,uint256 year,
        string memory specialization,
        string memory place,
        string memory degree) public {
            
        OnlyAdmin(cid);
        Education memory edu;
        edu.degree = degree;
        edu.place = place;
        edu.specialization = specialization;
        edu.year = year;
        education[id][i] = edu;
    }
    // Experiance
    function addExperiance(uint cid, uint id,uint256 year,
        string memory specialization,
        string memory place,
        string memory designation) public 
    {
        OnlyAdmin(cid);
        Experiance[] storage tmp = experiance[id];
        Experiance memory exp;
        exp.designation = designation;
        exp.specialization = specialization;
        exp.place = place;
        exp.year = year;
        tmp.push(exp);
        experiance[id] = tmp;
    }
    // TODO if remove index
     function editExperiance(uint cid,uint256 id,uint i,uint256 year,
        string memory specialization,
        string memory place,
        string memory designation) public  {
            OnlyAdmin(cid);
        Experiance memory exp;
        exp.designation = designation;
        exp.specialization = specialization;
        exp.place = place;
        exp.year = year;
        experiance[id][i] = exp;
    }
    function editLicenceNumber(uint cid, uint _id,uint256 license_number) public 
    {
        OnlyAdmin(cid);
        people[_id].info.license_number = license_number;
    }

    function editBankAccount(uint cid, uint _id,uint256 bank_Accounts) public
    {
        // TODO if remove
        OnlyAdmin(cid);
        people[_id].info.bank_Accounts.push(bank_Accounts);
    }
    function editInterest(uint cid, uint _id,string memory intrest) public
    {
        // TODO if remove
        OnlyAdmin(cid);
        people[_id].info.intrests.push(intrest);
    }
    function editFatherID(uint cid, uint _id,uint256 father_id) public
    {
        OnlyAdmin(cid);
        people[_id].info.father_id = father_id;
    }
     function editMotherID(uint cid, uint _id,uint256 mother_id) public 
    {
        OnlyAdmin(cid);
        people[_id].info.mother_id = mother_id;
    }
    function editAddress(uint cid, uint _id,string memory _address) public 
    {
        OnlyAdmin(cid);
        people[_id].info.home_address = _address;
    }
     function editPassport(uint cid, uint _id,string memory passport) public 
    {
        OnlyAdmin(cid);
        people[_id].info.passport = passport;
    }
     function editPassport(uint cid, uint _id,uint ms) public
    {
        OnlyAdmin(cid);
        people[_id].info.ms = Military_status(ms);
    }
 
    // function EditLogin(
    //     uint256 _id,
    //     string memory _password,
    //     string memory _email
    // ) public {
    //    // people[_id].sign.Password = _password;
    //     people[_id].sign.Email = _email;
    //     //string memory _user = people[_id].sign.UserName;
    //     hashLogInInfo(_id, _password);
    // }

    // function logIN(uint256 _id, string memory pass) public view  returns(bool){
    // string memory user = Strings.toString(_id);
    //     string memory tohashed = string.concat(user, pass);
    //     bytes32 _hash = hashDataSHA(tohashed);
    //     bytes32  login = signIn[_id];
    //     if (_hash.length != login.length) {
    //         return false;
    //     }
    //     return
    //         keccak256(abi.encodePacked(login)) ==
    //         keccak256(abi.encodePacked(_hash));
    //     //return  true;
    //}

    // TODO hashing login known user , later Email / user
    function hashLogInInfo(
        uint256 _id,
        string memory pass
    ) private {
        // string memory user = Strings.toString(_id);
        // string memory tohashed = string.concat(user, pass);
        bytes32 _hash = hashDataSHA(string.concat(Strings.toString(_id), pass));
        signIn[_id] = _hash;
    }

    // init hashing login
    function hashLogInInfo(
        uint256 _id,
        string memory pass,
        Person memory person
    ) private returns (Person memory) {
        //string memory user = Strings.toString(_id);
        //string memory tohashed = string.concat(user, pass);
        //console.log(tohashed);
        //console.log("sha");
        bytes32 _hash = hashDataSHA(string.concat(Strings.toString(_id), pass));
        //console.logBytes32(_hash);
        // string memory reversedInput = string(abi.encodePacked(_hash));
        signIn[_id] = _hash; // updateLogin hashing
        //console.logBytes32(signIn[_id]);
        person.sign.UserName = Strings.toString(_id);
       // person.sign.Password = pass;
        return person;
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
    // function isValidUser(string memory userName) private view returns (bool) {
    //     for (uint256 i = 0; i < users.length; i++) {
    //         string memory user = users[i];
    //         bool found = compare(userName, user);
    //         if (found) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    // function compare(
    //     string memory str1,
    //     string memory str2
    // ) private pure returns (bool) {
    //     if (bytes(str1).length != bytes(str2).length) {
    //         return false;
    //     }
    //     return
    //         keccak256(abi.encodePacked(str1)) ==
    //         keccak256(abi.encodePacked(str2));
    // }

    function hashDataSHA(string memory data) public pure returns (bytes32) {
       // bytes memory sad = bytes(data);
        //console.logBytes(sad);
        bytes32 hash = sha256(bytes(data));
        //console.logBytes32(hash);
        return hash;
    }

    //**  view / pure functions (getters) */
    function getPerson(uint256 id) public view returns (Person memory) {
        return people[id];
    }
    function getUser(uint index) public view returns (string memory) {
        return users[index];
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
    function getEducation(uint256 id) public view returns (Education[] memory) {
        return education[id];
    }
    function getEducationI(uint256 id,uint i) public view returns (Education memory) {
        return education[id][i];
    }
    function getExperiance(uint256 id) public view returns (Experiance[] memory) {
        return experiance[id];
    }
    function getExperianceI(uint256 id,uint i) public view returns (Experiance memory) {
        return experiance[id][i];
    }
}
