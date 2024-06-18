const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("KYC -Proxy Edition", function () {
  let KYC;
  let kyc;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    KYC = await ethers.getContractFactory("KYC -Proxy Edition");
    kyc = await upgrades.deployProxy(KYC, [1], { initializer: "initialize" });
    await kyc.deployed();
  });

  it("Should initialize with an admin", async function () {
    const admin = await kyc.getPerson(1);
    expect(admin.role).to.equal(0); // Admin role
  });

  it("Should add a person by admin", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John",
      "Doe",
      "John Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1 // User role
    );

    const person = await kyc.getPerson(2);
    expect(person.fName).to.equal("John");
    expect(person.lName).to.equal("Doe");
    expect(person.fullName).to.equal("John Doe");
    expect(person.gender).to.equal(0); // Male
    expect(person.role).to.equal(1); // User
  });

  it("Should revert when non-admin tries to add a person", async function () {
    await expect(
      kyc.connect(addr1).addPerson(
        1, // cid of the admin
        "John",
        "Doe",
        "John Doe",
        2,
        946684800, // bod (timestamp for 2000-01-01)
        0, // Male
        1 // User role
      )
    ).to.be.revertedWith("KYC__NOT_Have_Access()");
  });

  it("Should allow admin to edit person's wallet", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "Jane",
      "Doe",
      "Jane Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      1, // Female
      1 // User role
    );

    await kyc.connect(owner).editWallet(1, 2, addr1.address);

    const person = await kyc.getPerson(2);
    expect(person.person_wallet_address).to.equal(addr1.address);
  });

  it("Should allow admin to delete a person", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "Jane",
      "Doe",
      "Jane Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      1, // Female
      1 // User role
    );

    await kyc.connect(owner).deletePerson(1, 2);

    const person = await kyc.getPerson(2);
    expect(person.NID).to.equal(0); // Default value after deletion
  });

  it("Should add education details", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John",
      "Doe",
      "John Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1 // User role
    );

    await kyc
      .connect(owner)
      .addEducation(1, 2, 2022, "Computer Science", "MIT", "Bachelor");

    const education = await kyc.getEducation(2);
    expect(education.length).to.equal(1);
    expect(education[0].specialization).to.equal("Computer Science");
  });

  it("Should edit education details", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John",
      "Doe",
      "John Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1 // User role
    );

    await kyc
      .connect(owner)
      .addEducation(1, 2, 2022, "Computer Science", "MIT", "Bachelor");
    await kyc
      .connect(owner)
      .editEducation(1, 2, 0, 2023, "Computer Science", "MIT", "Master");

    const education = await kyc.getEducation(2);
    expect(education.length).to.equal(1);
    expect(education[0].degree).to.equal("Master");
  });

  it("Should delete education details", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John",
      "Doe",
      "John Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1 // User role
    );

    await kyc
      .connect(owner)
      .addEducation(1, 2, 2022, "Computer Science", "MIT", "Bachelor");
    await kyc.connect(owner).deleteEducation(1, 2, 0);

    const education = await kyc.getEducation(2);
    expect(education.length).to.equal(0);
  });

  it("Should login successfully with correct credentials", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "Jane",
      "Doe",
      "Jane Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      1, // Female
      1 // User role
    );

    await kyc.connect(owner).EditLogin(2, "newpassword");

    const loginSuccess = await kyc.logIN(2, "newpassword");
    expect(loginSuccess).to.be.true;
  });

  it("Should fail login with incorrect credentials", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "Jane",
      "Doe",
      "Jane Doe",
      2,
      946684800, // bod (timestamp for 2000-01-01)
      1, // Female
      1 // User role
    );

    const loginSuccess = await kyc.logIN(2, "wrongpassword");
    expect(loginSuccess).to.be.false;
  });
});
