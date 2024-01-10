// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFundingProjekat {
    address public kreator;
    uint256 public cilj;
    uint public rok;
    uint public procenat_za_produzenje;
    mapping (address => uint256) public doprinosi;
    uint256 public sakupljeni_doprinosi;
    bool public Finansirano;
    bool public Zavrseno;

    // Dogadjaji
    event CiljPostignut(uint256 sakupljeni_doprinosi);
    event TransferFinansija(address kreator, uint256 iznos);
    event RokPostignut(uint256 sakupljeni_doprinosi);
    event Refundacija(address ulagac, uint256 iznos);
    event RokNijeProduzen(string poruka);

    // Konstruktor
    constructor(uint256 ciljEther, uint rokUSatima, uint Procenat_Za_Produzenje_Roka) {
        kreator = msg.sender;
        cilj = ciljEther * 1 ether;
        rok = block.timestamp + (rokUSatima * 1 hours); // Pretvaranje sata u sekunde
        procenat_za_produzenje = Procenat_Za_Produzenje_Roka;
        Finansirano = false;
        Zavrseno = false;
    }

    modifier samo_kreator() {
        require(msg.sender == kreator, "Samo kreator projekta moze preuzeti doprinose ili pomjeriti rok.");
        _;
    }

    // Funkcija za doprinos
    function Finansiraj() public payable {
        require(block.timestamp <= rok, "Rok za doprinos je istekao.");
        require(!Zavrseno, "Cilj je vec postignut.");

        uint256 doprinos = msg.value;
        doprinosi[msg.sender] = doprinos;
        sakupljeni_doprinosi += doprinos;

        if (sakupljeni_doprinosi >= cilj){
            Finansirano = true;
            emit CiljPostignut(sakupljeni_doprinosi);
        }

        emit TransferFinansija(msg.sender, doprinos);
    }

    function PreuzmiDoprinose() public samo_kreator {
        require(Finansirano, "Cilj nije postignut.");
        require(!Zavrseno, "Crowdfunding je postignut.");

        Zavrseno = true;
        payable(kreator).transfer(address(this).balance);
    }

    function Refundiraj() public {
        require(!(block.timestamp >= rok), "Period za sakupljanje sredstava je istekao.");
        require(!Finansirano, "Cilj je postignut.");
        require(doprinosi[msg.sender] > 0, "Nema se sta refundirati");

    uint256 doprinos = doprinosi[msg.sender];
    doprinosi[msg.sender] = 0; // Bitno je ovim redosljedom to uraditi jer u DAO attack su prvo napravili transakciju pa onda azurirali stanje
    sakupljeni_doprinosi -= doprinos;         
    payable(msg.sender).transfer(doprinos); 
    emit TransferFinansija(msg.sender, doprinos);
    }

    function TrenutnoStanje() public  view returns (uint256) {
        return address(this).balance;
    }

    function PomjeriRok (uint rokUSatima) public samo_kreator {
        uint256 procenat_sakupljen = (sakupljeni_doprinosi/cilj)*100;
        if (procenat_sakupljen >= procenat_za_produzenje) {
            rok += rokUSatima * 1 hours;
        }
        else {
            emit RokNijeProduzen("Rok nije moguce produziti jer projekat nije sakupio dovoljnu kolicinu sredstava.");
        }
    }

}