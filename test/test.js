const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("KYC", function () {
  let KYC;
  let kyc;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    KYC = await ethers.getContractFactory("KYC");
    kyc = await upgrades.deployProxy(KYC, [1], { initializer: "initialize" });
    await kyc.waitForDeployment();
  });

  it("Should initialize with an admin", async function () {
    const admin = await kyc.getPerson(1);
    expect(admin[0].role).to.equal(0); // Admin role
  });

  it("Should add a person by admin", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    const person = await kyc.getPerson(2);
    expect(person[0].fullName).to.equal("John Doe");
    expect(person[0].gender).to.equal(0); // Male
    expect(person[0].role).to.equal(1); // User
  });

  it("Should revert when non-admin tries to add a person", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );
    const p = await kyc.getPerson(2);
    await expect(
      kyc.connect(owner).addPerson(
        2, // cid of the admin
        "John Doe",
        3,
        "engineer",
        946684800, // bod (timestamp for 2000-01-01)
        0, // Male
        1, // User role
        "img.jpg"
      )
    ).to.be.revertedWithCustomError(kyc, "KYC__NOT_Have_Access");
  });

  it("Should allow admin to edit person's wallet", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.connect(owner).editWallet(1, 2, addr1.address);

    const person = await kyc.getPerson(2);
    expect(person[0].person_wallet_address).to.equal(addr1.address);
  });

  it("Should allow admin to delete a person", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.connect(owner).deletePerson(1, 2);

    const person = await kyc.getPerson(2);
    expect(person[0].NID).to.equal(0); // Default value after deletion
  });

  it("Should edit education details", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc
      .connect(owner)
      .editEducation(1, 2, 2023, "Computer Science", "MIT", "Master");

    const p = await kyc.getPerson(2);
    expect(p[0].edu.degree).to.equal("Master");
    expect(p[0].edu.year).to.equal(2023);
    expect(p[0].edu.specialization).to.equal("Computer Science");
    expect(p[0].edu.place).to.equal("MIT");
  });

  it("Should delete education details", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.connect(owner).deleteEducation(1, 2);
    const p = await kyc.getPerson(2);
    expect(p[0].edu.year).to.equal(0);
  });

  it("Should login successfully with correct credentials", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      0, // User role
      "img.jpg"
    );

    await kyc.connect(owner).EditLogin(2, "newpassword");

    const loginSuccess = await kyc.logIN(2, "newpassword");
    expect(loginSuccess[0]).to.be.true;
  });

  it("Should fail login with incorrect credentials", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      0, // User role
      "img.jpg"
    );

    const loginSuccess = await kyc.logIN(2, "wrongpassword");
    expect(loginSuccess[0]).to.be.false;
  });
  it("Should Edit FullName Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editName(1, 2, "Ahmed Hesham");
    const p = await kyc.getPerson(2);
    expect(p[0].fullName).to.equal("Ahmed Hesham");
  });

  it("Should Edit Date of Birth Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.birthOfDate(1, 2, 2000);
    const p = await kyc.getPerson(2);
    expect(p[0].bod).to.equal(2000);
  });
  it("Should Edit Gender Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editGender(1, 2, 1);
    const p = await kyc.getPerson(2);
    expect(p[0].gender).to.equal(1);
  });
  it("Should Edit Job Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editJob(1, 2, "Pilot");
    const p = await kyc.getPerson(2);
    expect(p[0].job).to.equal("Pilot");
  });
  it("Should Edit Phone Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.EditPhone(1, 2, "01114134796");
    const p = await kyc.getPerson(2);
    expect(p[0].phone_number).to.equal("01114134796");
  });
  it("Should Edit Role Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editRole(1, 2, 0);
    const p = await kyc.getPerson(2);
    expect(p[0].role).to.equal(0);
  });
  it("Should Edit Licence Number Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editLicenceNumber(1, 2, 265485);
    const p = await kyc.getPerson(2);
    expect(p[0].info.license_number).to.equal(265485);
  });
  it("Should Edit Address Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editAddress(1, 2, "23 gamal abdel naser street");
    const p = await kyc.getPerson(2);
    expect(p[0].info.home_address).to.equal("23 gamal abdel naser street");
  });
  it("Should Edit Passport Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editPassport(1, 2, "2564784");
    const p = await kyc.getPerson(2);
    expect(p[0].info.passport).to.equal("2564784");
  });
  it("Should Edit Military Status Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editMilitaryStatus(1, 2, 1);
    const p = await kyc.getPerson(2);
    expect(p[0].info.ms).to.equal(1);
  });
  it("Should Add Bank Account Successfully", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      "img.jpg"
    );

    await kyc.editBankAccount(1, 2, 265485);
    const p = await kyc.getPerson(2);
    expect(p[0].info.bank_Accounts[0]).to.equal(265485);
  });
  it("Should Delete Person Successfully with Admin role Only", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      0, // User role
      "img.jpg"
    );

    await kyc.deletePerson(1, 2);
    const p = await kyc.getPerson(2);
    const n = await kyc.getNumberOfPersons();
    const a = await kyc.getNumberOfAdmins();
    expect(n).to.equal(1);
    expect(p[1]).to.be.false;
  });

  it("should return the correct hash for a given string", async function () {
    const inputString = "Hello, Ahmed!";
    const expectedHash = ethers.sha256(ethers.toUtf8Bytes(inputString));
    const result = await kyc.hashDataSHA("Hello, Ahmed!");
    expect(result).to.equal(expectedHash);
  });
  it("should get login hash correctly", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      0, // User role
      "img.jpg"
    );
    const result = await kyc.getLogin(2);
    const expectedHash = ethers.sha256(ethers.toUtf8Bytes("22"));
    expect(result).to.equal(expectedHash);
  });
});
