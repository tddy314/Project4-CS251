const { expect } = require("chai");
const { ethers } = require("hardhat");
const console = require("console");

describe("Testoefkkjg", function() {
    let contract, addr1, addr2, addr3;
    beforeEach(async function () {
        [addr1, addr2, addr3, addr4] = await ethers.getSigners();
        mycontract = await ethers.deployContract("TokenExchange");
    });
    it("hjhfjd", async function () {
        await mycontract.connect(addr1).setValue();
        try{
        await mycontract.connect(addr1).swapETHForTokens(101000, {value: ethers.utils.parseEther("100")});
        }
        catch(error) {
            console.log(error.message);
        }
        expect(1).to.equal(1);
        let vv = await mycontract.connect(addr1).check_token();
        console.log(vv);
    });
})