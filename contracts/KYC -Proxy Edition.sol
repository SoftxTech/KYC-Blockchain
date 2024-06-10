// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// errors
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
        Admin, // owner could add admins and other roles , full control
        User
    }
    // when do operations check and if not revert
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
        //string license_image; // check valid with AI
        //string image; // store hash verify idententy
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
    uint256[] private nationalIDs; // keys - prevent dublicate
    uint256[] private users; // users/admins list

    // Events
    event AddPerson(uint256 indexed Nid, string indexed fullName);

    // edit field log

    function initialize(uint256 _id) initializer public {
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
     addPerson( _id, msg.sender);
    //_disableInitializers();
}

function _authorizeUpgrade(address newImplementation) internal override
{
    
}
    //TODO check token boolean if valid | get session of token info
    function  OnlyAdmin(uint256 id)  internal view {
        Roles role = people[id].role;
        //TODO check login
        if (role != Roles.Admin) {
            revert KYC__NOT_Have_Access();
        }
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
            person = hashLogInInfo(_id, Strings.toString(_id), person);
            // users[users.length] = Strings.toString(_id);
            users.push(_id);
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
    ) internal  {
        if (_id<0)
        {
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
        people[_id].person_wallet_address = wallet_address;
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
    // function editEmail (uint cid, uint _id,string memory email) public 
    // {
    //     OnlyAdmin(cid);
    //     people[_id].email = email;
    // }
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
        education[id][i] = Education(year,specialization,place,degree);
    }
    function deleteEducation(uint cid,uint256 id,uint i) public {
        OnlyAdmin(cid);
        for (uint index = i; index < education[id].length; index++) 
        {
            if(index != education[id].length-1){
            education[id][index] = education[id][index+1];
            }
        }
        delete education[id][education[id].length-1];
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
        experiance[id][i] = Experiance(year,specialization,designation,place);
    }
    function deleteExperiance(uint cid,uint256 id,uint i) public {
        OnlyAdmin(cid);
          for (uint index = i; index < experiance[id].length; index++) 
        {
            if(index != experiance[id].length-1)
            experiance[id][index] = experiance[id][index+1];
        }
        delete experiance[id][experiance[id].length-1];
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
     function editMilitaryStatus(uint cid, uint _id,uint ms) public
    {
        OnlyAdmin(cid);
        people[_id].info.ms = Military_status(ms);
    }
    function deletePerson(uint cid, uint _id) public
    {
        OnlyAdmin(cid);
        uint iid = 0;
        uint uid = 0;
        for(iid ; iid <nationalIDs.length;iid++){
            if (nationalIDs[iid]==_id)
                break;
        }  

        for(uint index = iid ; index <nationalIDs.length-1;index++){
            if(index != nationalIDs.length-1)
                nationalIDs[index]=nationalIDs[index+1];
        }

        if(people[_id].role==Roles.Admin)
        {
            for(uid ; uid < users.length;uid++)
            {
                if (users[uid]==_id)
                    break;
            }   
            for(uint index = uid ; index <users.length-1;index++)
            {
                if(index != users.length-1)
                    users[index]=users[index+1];
            }
        }
        
        delete people[_id];
    }
 
    function EditLogin(
        uint256 _id,
        string memory _password
    ) public {
       people[_id].sign.Password = _password;
        //string memory _user = people[_id].sign.UserName;
        hashLogInInfo(_id, _password);
    }

    function logIN(uint256 _id, string memory pass) public view  returns(bool){
        if (hashDataSHA(string.concat(Strings.toString(_id), pass)).length != signIn[_id].length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(signIn[_id])) ==
            keccak256(abi.encodePacked(hashDataSHA(string.concat(Strings.toString(_id), pass))));
    }

    // TODO hashing login known user , later Email / user
    function hashLogInInfo(
        uint256 _id,
        string memory pass
    ) internal {
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
        person.sign.UserName = Strings.toString(_id);
        return person;
    }

//**  middle functions */
    function grantPermission(Roles _role) internal pure returns (Permissions) {
         if (_role == Roles.Admin) {
            return Permissions.Full;
        } else  {
            return Permissions.Non;
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


    function hashDataSHA(string memory data) public pure returns (bytes32) {
        bytes32 hash = sha256(bytes(data));
        return hash;
    }

    //**  view / pure functions (getters) */
    function getPerson(uint256 id) public view returns (Person memory) {
        return people[id];
    }
    function getUser(uint index) public view returns (uint256) {
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