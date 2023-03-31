pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Loteria {
    uint256 public ticketPrice = 1 ether; // Precio del boleto en USDT
    uint256 public totalTickets; // Total de boletos vendidos
    uint256 public maxTickets = 100; // Cantidad máxima de boletos disponibles
    address public tokenAddress = 0x55d398326f99059fF775485246999027B3197955; // Dirección del contrato USDT en BSC
    address payable public owner;
    bool public gameActive; // Estado del juego (activo/inactivo)
    uint256 public randomNumber; // Número aleatorio generado al final del juego
    
    struct TicketHolder {
        uint256 ticketsBought; // Número de boletos comprados
        bool hasClaimed; // Si ha reclamado sus premios
    }
    
    mapping(address => TicketHolder) public ticketHolders; // Saldo de boletos por participante
    
    event NewTicketSold(address indexed buyer, uint256 numberOfTickets);
    event LotteryEnded(uint256 winningNumber, uint256 totalPrize);
    event ClaimedPrize(address indexed claimer, uint256 prizeAmount);
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    function startGame() external onlyOwner {
        require(!gameActive, "Game is already active");
        gameActive = true;
    }
    
    function endGame() external onlyOwner {
        require(gameActive, "Game is not active");
        gameActive = false;
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, totalTickets)));
        emit LotteryEnded(randomNumber, totalTickets * ticketPrice);
    }
    
    function buyTicket(uint256 numberOfTickets) external {
        require(gameActive, "Game is not active");
        require(totalTickets + numberOfTickets <= maxTickets, "Maximum number of tickets reached");
        IERC20 usdtToken = IERC20(tokenAddress);
        uint256 totalAmount = numberOfTickets * ticketPrice;
        require(usdtToken.transferFrom(msg.sender, address(this), totalAmount), "Transfer failed");
        ticketHolders[msg.sender].ticketsBought += numberOfTickets;
        totalTickets += numberOfTickets;
        emit NewTicketSold(msg.sender, numberOfTickets);
    }
    
    function claimPrize() external {
        require(!ticketHolders[msg.sender].hasClaimed, "You have already claimed your prize");
        require(!gameActive, "Game is still active");
        uint256 prizeAmount = calculatePrize(msg.sender);
        require(prizeAmount > 0, "You did not win a prize");
        ticketHolders[msg.sender].hasClaimed = true;
        IERC20 usdtToken = IERC20(tokenAddress);
        require(usdtToken.balanceOf(address(this)) >= prizeAmount, "Not enough funds to pay prize");
        require(usdtToken.transfer(msg.sender, prizeAmount), "Transfer failed");
        emit ClaimedPrize(msg.sender, prizeAmount);
    }
    
    function calculatePrize(address ticketHolder) public view returns (uint256) {
require(!gameActive, "Game is still active");
require(totalTickets > 0, "No tickets were sold");
if (randomNumber == 0) {
return 0; // Si el número ganador no fue generado, no hay premios
}
uint256 holderTickets = ticketHolders[ticketHolder].ticketsBought;
if (holderTickets == 0) {
return 0; // Si el participante no tiene boletos, no hay premio
}
uint256 winningTicket = randomNumber % totalTickets + 1;
if (winningTicket <= holderTickets) {
uint256 prizePool = totalTickets * ticketPrice;
uint256 prizeAmount = prizePool * 80 / 100; // El premio es el 80% del total recaudado
return prizeAmount / holderTickets;
}
return 0; // Si el participante no tiene el boleto ganador, no hay premio
}
function withdrawFunds() external onlyOwner {
    require(!gameActive, "Game is still active");
    IERC20 usdtToken = IERC20(tokenAddress);
    require(usdtToken.balanceOf(address(this)) > 0, "No funds to withdraw");
    require(usdtToken.transfer(owner, usdtToken.balanceOf(address(this))), "Transfer failed");
}

