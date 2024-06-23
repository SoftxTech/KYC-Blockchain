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
    expect(admin.role).to.equal(0n); // Admin role
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    const person = await kyc.getPerson(2);
    expect(person.fullName).to.equal("John Doe");
    expect(person.gender).to.equal(0n); // Male
    expect(person.role).to.equal(1n); // User
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
      2000,
      "sc",
      "azhar",
      "bc"
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
        2000,
        "sc",
        "azhar",
        "bc"
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.connect(owner).editWallet(1, 2, addr1.address);

    const person = await kyc.getPerson(2);
    expect(person.person_wallet_address).to.equal(addr1.address);
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.connect(owner).deletePerson(1, 2);

    const person = await kyc.getPerson(2);
    expect(person.NID).to.equal(0n); // Default value after deletion
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc
      .connect(owner)
      .editEducation(1, 2, 2023, "Computer Science", "MIT", "Master");

    const p = await kyc.getPerson(2);
    expect(p.edu.degree).to.equal("Master");
    expect(p.edu.year).to.equal(2023n);
    expect(p.edu.specialization).to.equal("Computer Science");
    expect(p.edu.place).to.equal("MIT");
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.connect(owner).deleteEducation(1, 2);
    const p = await kyc.getPerson(2);
    expect(p.edu.year).to.equal(0n);
  });

  it("Should login successfully with correct credentials", async function () {
    await kyc.connect(owner).addPerson(
      1, // cid of the admin
      "John Doe",
      2,
      "engineer",
      946684800, // bod (timestamp for 2000-01-01)
      0, // Male
      1, // User role
      2000,
      "sc",
      "azhar",
      "bc"
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
      1, // User role
      2000,
      "sc",
      "azhar",
      "bc"
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.editName(1, 2, "Ahmed Hesham");
    const p = await kyc.getPerson(2);
    expect(p.fullName).to.equal("Ahmed Hesham");
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.birthOfDate(1, 2, 2000);
    const p = await kyc.getPerson(2);
    expect(p.bod).to.equal(2000n);
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.birthOfDate(1, 2, 2000);
    const p = await kyc.getPerson(2);
    expect(p.bod).to.equal(2000n);
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.editGender(1, 2, 1);
    const p = await kyc.getPerson(2);
    expect(p.gender).to.equal(1n);
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.editJob(1, 2, "Pilot");
    const p = await kyc.getPerson(2);
    expect(p.job).to.equal("Pilot");
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.EditPhone(1, 2, "01114134796");
    const p = await kyc.getPerson(2);
    expect(p.phone_number).to.equal("01114134796");
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
      2000,
      "sc",
      "azhar",
      "bc"
    );

    await kyc.editRole(1, 2, 0);
    const p = await kyc.getPerson(2);
    expect(p.role).to.equal(0n);
  });
});
