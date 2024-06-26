pragma solidity >=0.6.12 <0.9.0;

import "band.sol";
import "start.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Auction is Code{
    Band band = new Band();

    struct Auctioner {
        uint indentificationNumber;
        string [] item;
    }

    struct bidItem {
        string nameItem;
        uint startValue;
    }

    mapping (uint => Auctioner) listJoin;
    mapping (string => uint) checkItem;
    mapping (uint => uint) public checkJoin;
    mapping (uint => uint) time;
    mapping (string => uint) public count;
    mapping (string => uint) public ownerItem;
    mapping (uint => bidItem) trade;

    bidItem []items;
    bidItem [] menu;
    uint [] joiners;
    uint [] check;

    event joiner (uint password, address account);
    event item (string name, uint value);
    event result (uint winner, string nameOfItem);

    constructor() {
        count["limit joiner"] = 2;
        count["limit item"] = 5;
        count["id item"] = 0;
    }

    function addItem(string memory nameOfItem, uint value) public {
        if(items.length < 5){
            items.push(bidItem(nameOfItem, value));
            checkItem[nameOfItem] = 1;
            count["limit item"] --; 
            emit item (nameOfItem, value);
        }
        else{
            emit failure("cannot add item");
        }
    }

    function joinAuction(address addressUser,string memory name, uint password) external payable {
        require(count["limit item"] == 0, "cannot join auction yet");
        band.addUser(addressUser, name, 0);
        if(count["limit joiner"] != 0 && listJoin[password].indentificationNumber == 0 && band.getId(password) == 1
        && address(this).balance >= 1 ether){
            string [] memory emptyArray = new string[](0);
            uint code = createCode(createCode((block.timestamp))) / 1e13;
            listJoin[code] = Auctioner(code, emptyArray);
            joiners.push(code);
            count["limit joiner"] --;
            if(count["limit joiner"] == 0){
                count["time access"] = block.timestamp;
                count["time stop"] = count["time access"];
            }
            sendEther();
            emit joiner(code, addressUser);
        }
        else{
            emit failure("cannot join auction");
        }
    }

    // function show(address addressUser,string memory name,uint balance, uint password) public returns(uint) {
    //     band.addUser(addressUser, name, balance);
    //     return band.getBalance(id);
    // }

    function bid (string memory yourChoose, uint yourId) public{
        require(count["limit joiner"] == 0, "cannot bid yet");
        if(listJoin[yourId].indentificationNumber == yourId){
            uint money = stringToUint(yourChoose);       

            string memory str = Strings.toString(money);
            bytes memory temp1 = bytes(yourChoose);
            bytes memory temp2 = bytes(str);
            
            if(money == 0 || temp1.length != temp2.length){
                checkJoin[yourId] = 1;
                check.push(yourId);
                emit failure("skipped");
            }
            if(money > items[count["id item"]].startValue && checkJoin[yourId] == 0 &&
            block.timestamp >= time[yourId] + 10 seconds){
                count["best id"] = yourId;
                items[count["id item"]].startValue = money;
            }       
            time[yourId] = block.timestamp;
            if(count["time access"] + 1 minutes <= block.timestamp){
                listJoin[count["best id"]].item.push(items[count["id item"]].nameItem); 
                ownerItem[items[count["id item"]].nameItem] = count["best id"];
                count["time access"] = block.timestamp;
                count["id item"] ++;
                for(uint i = 0; i < check.length; i++){
                    delete checkJoin[check[i]];
                }
                delete check;
                emit result(count["best id"], items[count["id item"]].nameItem);
            }
            if(block.timestamp >= count["time stop"] + 5 minutes){
                delete items;
                for(uint i = 0; i < joiners.length; i++){
                    delete listJoin[joiners[i]];
                }
                delete joiners;

                count["limit joiner"] = 2;
                count["limit item"] = 5;
                count["id item"] = 0;
            }
        }
        else{
            emit failure("this id is not available");
        }
    } 

    function show(uint code) public view returns(string[] memory){
        return listJoin[code].item;
    }

    function itemSale(uint yourCode, string memory name, uint money) public {
        if(ownerItem[name] == yourCode){
            menu.push(bidItem(name, money));
            trade[yourCode] = bidItem(name,money);
        }
        else{
            emit failure("you are not owner of this item or this item is not to buy");
        }
    }

    function buy(uint yourCode, uint money, string memory name) public {
        uint b1 = uint(keccak256(abi.encodePacked(name)));
        uint b2 = uint(keccak256(abi.encodePacked(trade[yourCode].nameItem)));
        if(money >= trade[yourCode].startValue && b1 == b2){
            listJoin[yourCode].item.push(trade[yourCode].nameItem);
            uint index;
            for(uint i = 0; i < menu.length; i++){
                b1 = uint(keccak256(abi.encodePacked(menu[i].nameItem)));
                b2 = uint(keccak256(abi.encodePacked(name)));
                if(b1 == b2) {
                    index = i;
                    break;
                }
            }
            bidItem memory temp = menu[index];
            menu[index] = menu[menu.length - 1];
            menu[menu.length - 1] = temp;
            menu.pop();
        }
    }

}