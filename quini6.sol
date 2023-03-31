// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Loteria {
    uint256 public ticketPrice = 1 ether; // Precio del boleto en USDT
    uint256 public totalTickets; // Total de boletos vendidos
    uint256 public maxTickets = 100; // Cantidad máxima de boletos disponibles
    address public tokenAddress = 0x55d398326f99059fF775485246999027B3197955; // Dirección del contrato USDT en BSC
   
    IERC20 public token;

    address payable public owner;
    bool public gameActive; // Estado del juego (activo/inactivo)
    uint256 public randomNumber; // Número aleatorio generado al final del juego
    
    struct TicketHolder {
        uint256 ticketsBought; // Número de boletos comprados
        bool hasClaimed; // Si ha reclamado sus premios
    }

    mapping (address => TicketHolder) public tickets; // Mapeo de direcciones a compradores de boletos

    event TicketBought(address indexed buyer, uint256 ticketsBought);
    event TicketPriceUpdated(uint256 newPrice);
    event GameActivated();
    event GameDeactivated();
    event RandomNumberGenerated(uint256 randomNumber);
    event PrizeClaimed(address indexed winner, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        token = IERC20(tokenAddress);
    }

    function buyTicket(uint256 _numberOfTickets) external {
        require(gameActive, "El juego no está activo");
        require(_numberOfTickets > 0, "Debes comprar al menos un boleto");
        require(totalTickets + _numberOfTickets <= maxTickets, "No hay suficientes boletos disponibles");

        uint256 priceInTokens = _numberOfTickets * ticketPrice;
        require(token.allowance(msg.sender, address(this)) >= priceInTokens, "Debes aprobar la transferencia de USDT");

        token.transferFrom(msg.sender, address(this), priceInTokens);
        totalTickets += _numberOfTickets;
        tickets[msg.sender].ticketsBought += _numberOfTickets;

        emit TicketBought(msg.sender, _numberOfTickets);
    }

    function updateTicketPrice(uint256 _newPrice) external {
        require(msg.sender == owner, "Solo el dueño puede actualizar el precio del boleto");
        ticketPrice = _newPrice;

        emit TicketPriceUpdated(_newPrice);
    }

    function activateGame() external {
        require(msg.sender == owner, "Solo el dueño puede activar el juego");
        require(!gameActive, "El juego ya está activo");

        gameActive = true;

        emit GameActivated();
    }

    function deactivateGame() external {
        require(msg.sender == owner, "Solo el dueño puede desactivar el juego");
        require(gameActive, "El juego ya está desactivado");

        gameActive = false;

        emit GameDeactivated();
    }

    function generateRandomNumber() external {
        require(msg.sender == owner, "Solo el dueño puede generar el número aleatorio");
        require(!gameActive, "El juego debe estar desactivado para generar el número aleatorio");

        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        emit RandomNumberGenerated(randomNumber);
    }

    function claimPrize() external {
        require(gameActive == false, "El juego todavía está activ
