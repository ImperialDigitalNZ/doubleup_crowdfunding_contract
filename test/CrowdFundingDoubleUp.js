var CrowdFundingDoubleUp = artifacts.require("./CrowdFundingDoubleUp.sol");

contract('CrowdFundingDoubleUp', function(accounts) {
  it("should send ether correctly", function() {

    var funding = accounts[0];
    var buyer_1 = accounts[2];

    var before_transaction = web3.fromWei(web3.eth.getBalance(buyer_1), "ether");

    return CrowdFundingDoubleUp.deployed().then(function(instance) {
      var funding = accounts[0];
      var buyer_1 = accounts[2];

      instance.sendTransaction.call(buyer_1, web3.toWei(200, "ether"));  // 20 ether
    }).then(function() {
      var funding = accounts[0];
      var buyer_1 = accounts[2];

      var after_transaction = web3.fromWei(web3.eth.getBalance(buyer_1), "ether");   
      assert.equal(web3.fromWei(web3.eth.getBalance(funding), "ether"), web3.toWei(200, "ether"), 
      "It should be 200 ether.");   
    });
  });
  it("should call a function that sets amount of tokens per ether. once amount set, cannot change", function() {
    return CrowdFundingDoubleUp.deployed().then(function(instance) {
      instance.setTokensPerEther.call(3000000);
      instance.setTokensPerEther.call(2000000);
      assert.equal(instance.getTokenPerEther.call(), 3000000, "It should be 3000000.");
    });
  });
  it("should return a bonus rate of the presale period. presale ends in 3 mins", function() {

    return CrowdFundingDoubleUp.deployed().then(function(instance) {
      var bonus_p = instance.getBonusRate.call(1506032040);
      var bonus_1 = instance.getBonusRate.call(1506032220);
      var bonus_2 = instance.getBonusRate.call(1506032400);
      var bonus_3 = instance.getBonusRate.call(1506032580);
      var bonus_4 = instance.getBonusRate.call(1506032820);

      console.log(bonus_p);
      console.log(bonus_1);
      console.log(bonus_2);
      console.log(bonus_3);
      console.log(bonus_4);
    });
  });
  it("should return true if presale ends by reaching goal", function() {
    
    
        return CrowdFundingDoubleUp.deployed().then(function(instance) {

          var buyer_1 = accounts[2];

          var before = instance.stopPresale.call();

          instance.sendTransaction.call(buyer_1, web3.toWei(200, "ether"));  // 20 ether

          var after = instance.stopPresale().call();

          console.log("before :" + before);
          console.log("after :" + after);

          assert.equal(after, true, "must be true");
        });
      });
});
