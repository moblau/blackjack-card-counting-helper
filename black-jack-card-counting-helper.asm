TITLE Final Project - Black Jack

This project will teach the user how to count cards playing black jack.
It is written in assembly language.

;By Morris Blaustein


;            HOW TO PLAY

;            PRESS   h   TO   HIT
;            PRESS   s   TO   STAND
;            PRESS   d   TO   DOUBLEDOWN
;            PRESS   t   TO   SPLIT

;            Have fun!

INCLUDE Irvine32.inc

;Constants

numDiffCards = 13
numCards = 51
cardWidth = 7
cardHeight = 8
cardGap = 3

;bit 14 and 15 are used to hide one of the first dealer cards, including the dealer
score

Hand STRUCT
      cards BYTE 10 DUP(0)
      value BYTE 0
      s BYTE 0,0,0,0,1
Hand ENDS

.data

;Count is used to keep track of the score count
count SBYTE 0

;Deck Variables
deck BYTE 52 DUP('?')
cardsremaining DWORD 51
cards BYTE 'A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K'
q BYTE 13 DUP(0)

;Hand Variables
dealer Hand {}
player Hand {}
split Hand {}

;used to hold player input
move BYTE ?

;player chip stack
playerchips WORD 1000
;Text Strings to diplay
dealerscore BYTE "Dealer:",0
playerscore BYTE "Player:",0
ctprompt BYTE "Count:",0
bust BYTE "BUSTED!",0
lose BYTE "You Lose :(",0
Chipstack BYTE "Chipstack:",0
betprompt BYTE "Bet:",0
win BYTE "You Win!",0
tie BYTE "Tie -_-",0

;card buffer used for displaying card value
card BYTE ?

;hold the player bet for each round
bet WORD ?

;Used to calculate the hand score when there are aces
numAces BYTE 0


.code

;----------------------------------------------------
main PROC

;Runs the game, through various jumps and loops

;--------------------------------------------------
;Shuffles the deck
S:
      call Randomize
      call shuffle

;Marks the start of a new hand
NewHand:
      mov BYTE PTR dealer[14],1
      mov ecx, 16

;Clears the split hand every new hand
clr:
      mov BYTE PTR split[ecx-1],0
      loop clr

        mov eax, white+(green*16)
        call SetTextColor
        call Clrscr
        mov dl,66
        mov dh,22+cardHeight+cardGap
        call Gotoxy
        mov edx, OFFSET ctprompt
        call WriteString
        movsx eax, count
        call WriteInt


        mov dl, 49
        mov dh, 22+cardHeight+cardGap
     call Gotoxy
     mov edx, OFFSET Chipstack
     call WriteString
     movzx eax, playerchips
     call WriteInt

     mov dl, 40
     mov dh, 22+cardHeight+cardGap
     call Gotoxy
     mov edx, OFFSET betprompt
     call WriteString
     call ReadInt
     mov bet, ax

     mov   ebx,   OFFSET dealer
     mov   BYTE   PTR [ebx+11],0
     mov   ebx,   OFFSET player
     mov   BYTE   PTR [ebx+11],0

     mov eax, cardsRemaining
     mov ebx, OFFSET dealer
     call dealcard
     call dealcard
     mov ebx, OFFSET player
     call dealcard
     call dealcard
     mov eax, OFFSET dealer
     call eval
     mov eax, OFFSET player
     call eval
     mov eax, OFFSET split
     call eval

     mov eax, OFFSET dealer
     mov ebx, OFFSET player
     mov edx, OFFSET split
     call display

;Jumps here if player hits
Hit:
      call ReadChar
      mov move, al

;PLAYER HIT
      .IF move == 'h'
            mov ebx, OFFSET player
            call dealcard
      .ENDIF
      mov al, player.cards[0]

;PLAYER SPLIT
      .IF move == 't' && al == player.cards[1]
            mov split.cards[0],al
            inc BYTE PTR split[11]
            dec BYTE PTR player[11]
      .ENDIF

;PLAYER STAND
      .IF move == 's'
           jmp Done
     .ENDIF

;PLAYER DOUBLE DOWN
      .IF move == 'd'
            mov ax, bet
            add bet,ax
            mov ebx, OFFSET player
            call dealcard
            mov eax, OFFSET player
            call eval
            jmp Done
      .ENDIF
      mov eax, OFFSET dealer
      call eval
      mov eax, OFFSET player
      call eval
      mov eax, OFFSET split
      call eval
      mov eax, OFFSET player
      mov ebx, OFFSET dealer
      mov edx, OFFSET split
      call display

;Checks for player bust
      .IF player.value > 21
            mov dl, 5
            mov dh, 22
            call Gotoxy
            mov edx, OFFSET bust
            call WriteString
            mov eax,5000
            call Delay
            mov bx, bet
            sub playerchips,bx
            .IF BYTE PTR split[11] > 0
            jmp Done
            .ELSE
            jmp NewHand
            .ENDIF
      .ENDIF
      jmp Hit
Done:

;When first hand is finished, check if there are values in the split hand.
;If so, repeat the same steps for the new split hand
      .IF BYTE PTR split[11] > 0
      call ReadChar
      mov move, al
      .ENDIF
      .IF move == 'h'
            mov ebx, OFFSET split
            call dealcard
            mov eax, OFFSET player
            call eval
            mov eax, OFFSET dealer
            call eval
            mov eax, OFFSET split
            call eval
           mov eax, OFFSET player
           mov ebx, OFFSET dealer
           mov edx, OFFSET split
           call display
           jmp Done
     .ENDIF
     .IF split.value > 21
           mov dl, 5
           mov dh, 36
           call Gotoxy
           mov edx, OFFSET bust
           call WriteString
           mov eax,5000
           call Delay
           mov bx, bet
           sub playerchips,bx
           jmp NewHand
     .ENDIF
     .IF move == 's'
           jmp DealerHit
     .ENDIF

;When the players turn is over, the dealer will hit based on the rules below
DealerHit:
      mov eax, 2000
      call Delay
      .IF dealer.value <= 16
            mov ebx, OFFSET dealer
            call dealcard
      .ENDIF
      mov eax, OFFSET dealer
      call eval
      mov eax, OFFSET player
      mov ebx, OFFSET dealer
      mov edx, OFFSET split
      call display
      .IF dealer.value > 21
            mov dl, 5
            mov dh, 22
            call Gotoxy
            mov edx, OFFSET win
            call WriteString
            mov eax,5000
            call Delay
            mov bx, bet
            add playerchips, bx
            jmp e
      .ENDIF
      .IF dealer.value < 16
      jmp DealerHit
      .ENDIF
      .IF dealer.value <= 21 || dealer.value >16
      jmp comparescores
      .ENDIF
      jmp DealerHit

;The game will check the scores of the hands if nobody has won the round yet
comparescores:
;Checks if there is a score comparison needed for the split hand
      cmp byte PTR [split+11],0
      je nosplit
      mov al, dealer.value
      mov bx, bet
      .IF al > split.value
            sub playerchips,bx
            mov dl, 5
            mov dh, 22+ cardHeight + 4
            call Gotoxy
            mov edx, OFFSET lose
            call WriteString
      .ELSEIF al == split.value
            mov dl, 5
            mov dh, 22+ cardHeight + 4
            call Gotoxy
            mov edx, OFFSET tie
            call WriteString
      .ELSE
            mov dl, 5
            mov dh, 22+ cardHeight + 4
            call Gotoxy
            mov edx, OFFSET win
            call WriteString
            add playerchips,bx
      .ENDIF
nosplit:
      mov al, dealer.value
      mov bx, bet
      .IF al > player.value
            sub playerchips,bx
            mov dl, 5
            mov dh, 22
            call Gotoxy
            mov edx, OFFSET lose
            call WriteString
      .ELSEIF al == player.value
            mov dl, 5
            mov dh, 22
            call Gotoxy
            mov edx, OFFSET tie
            call WriteString
      .ELSE
            mov dl, 5
            mov dh, 22
            call Gotoxy
            mov edx, OFFSET win
            call WriteString
            add playerchips,bx
      .ENDIF
      mov eax, 5000
      call Delay

;Shuffles the deck if it is less than half full
      .IF cardsRemaining < 26
            mov count, 0
            call shuffle
      .ENDIF
e:
;Checks to see if the player still has chips
      cmp playerchips,0
      ja NewHand
      call Clrscr
      exit
main ENDP

;----------------------------------------------------
shuffle PROC
;The shuffle procedure will reload the deck with 52 new random cards
;----------------------------------------------------
      mov ecx, numCards
L1:
R:
      mov eax, numDiffCards
      call RandomRange
      cmp q[eax],4
      je R
      add q[eax],1
      mov bl, cards[eax]
      mov deck[ecx],bl
      Loop L1
      mov ecx, numDiffCards
L2:
      mov q[ecx-1],0
      Loop L2
      mov cardsremaining, numCards
      ret
shuffle ENDP

;----------------------------------------------------
dealcard PROC uses ebx
;The deal card takes the offset of the hand in ebx
;and updates the hand and count based on the card drawn
;----------------------------------------------------
      mov ecx,cardsRemaining
      movzx edx,deck[ecx]
      .IF deck[ecx] =='2' || deck[ecx] =='3' || deck[ecx] =='4' || deck[ecx] =='5'
            inc count
      .ENDIF
      .IF deck[ecx] =='T' || deck[ecx] =='J' || deck[ecx] =='Q' || deck[ecx] =='K'
|| deck[ecx] =='A'
            dec count
      .ENDIF
      dec cardsRemaining
      add BYTE PTR [ebx+11],1
      add bl, BYTE PTR [ebx+11]
      dec ebx
      mov BYTE PTR [ebx], dl
      sub bl, BYTE PTR [ebx+11]



      ret
dealcard ENDP

;----------------------------------------------------
display PROC uses eax ebx edx
;The display procedure runs the bulk of the graphic interface.
;It takes the offset of the three hands in eax, ebx, and edx
;----------------------------------------------------
      push edx
      push eax
      push ebx
      mov eax, white+(green*16)
      call SetTextColor
      call Clrscr

     mov dl,66
     mov dh,22+cardHeight+cardGap
     call Gotoxy
     mov edx, OFFSET ctprompt
     call WriteString
     movsx eax, count
     call WriteInt

     mov dl, 49
     mov dh, 22+cardHeight+cardGap
     call Gotoxy
     mov edx, OFFSET Chipstack
     call WriteString
     movzx eax, playerchips
     call WriteInt

     mov dl, 40
     mov dh, 22+cardHeight+cardGap
     call Gotoxy
     mov edx, OFFSET betprompt
     call WriteString
     movzx eax, bet
     call WriteInt

     mov dl, 65
     mov dh, 6
     call Gotoxy
     movzx eax , dealer.value
     .IF BYTE PTR dealer[14] == 1
     .IF dealer.cards[1] == '2'
     sub eax, 2
     .ENDIF
     .IF dealer.cards[1] == '3'
     sub eax, 3
     .ENDIF
     .IF dealer.cards[1] == '4'
     sub eax, 4
     .ENDIF
     .IF dealer.cards[1] == '5'
     sub eax, 5
     .ENDIF
     .IF dealer.cards[1] == '6'
     sub eax, 6
     .ENDIF
     .IF dealer.cards[1] == '7'
     sub eax, 7
     .ENDIF
     .IF dealer.cards[1] == '8'
     sub eax, 8
      .ENDIF
      .IF dealer.cards[1] == '9'
      sub eax, 9
      .ENDIF
      .IF dealer.cards[1] == 'T'||dealer.cards[1] == 'J'||dealer.cards[1] == 'Q'||
dealer.cards[1] == 'K'
      sub eax, 10
      .ENDIF
      .IF dealer.cards[1] == 'A'
      sub eax, 11
      .ENDIF
      mov BYTE PTR dealer[14],0
      .ENDIF
      mov edx, OFFSET dealerscore
      call WriteString
      call WriteInt
      mov dl, 65
      mov dh, 16
      call Gotoxy
      mov edx, OFFSET playerscore
      call WriteString
      movzx eax, player.value
      call WriteInt

     .IF BYTE PTR split[11] > 0
     mov dl, 65
     mov dh, 28
     call Gotoxy
     mov edx, OFFSET playerscore
     call WriteString
     movzx eax, split.value
     call WriteInt
     .ENDIF
     pop eax
     movzx ecx, BYTE PTR [eax+11]
     mov dl, 2
     mov dh, 1
     .IF ecx == 2
     mov BYTE PTR dealer[15],1
     .ENDIF

;Displays dealer hand
D:
      .IF BYTE PTR dealer[15] == 1
      mov al, ' '
      mov BYTE PTR dealer[15],0
      .ELSE
      mov al, dealer.cards[ecx-1]
      .ENDIF
      push ecx
      call showcard
      add dl, cardWidth + cardGap
      pop ecx
      loop D

     mov dl, 2
     mov dh,12
     pop ebx
     movzx ecx, BYTE PTR [ebx+11]
;Displays player hand
P:
      mov al, player.cards[ecx-1]
      push ecx
      call showcard
      add dl, cardWidth + cardGap
      pop ecx
      loop P

     pop eax
     movzx ecx, BYTE PTR [eax+11]
     mov dl, 2
     mov dh, 24
     .IF ecx > 0

;Displays split hand, if player chose to split
S:
      mov al, split.cards[ecx-1]
      push ecx
      call showcard
      add dl, cardWidth + cardGap
      pop ecx
      loop S
      .ENDIF



      ret
display ENDP
;----------------------------------------------------
showcard PROC USES eax edx
;The showcard PROC is a subprocedure used in display
;It takes the loc of the new card in edx and the card value in eax

;----------------------------------------------------
      mov card, al
      mov ebx, edx
      mov eax, white+(white*16)
      call SetTextColor
      call Gotoxy
      mov ecx, cardHeight
      mov al, ' '
Top:
      call WriteChar
      Loop Top
      add dh,cardHeight
      mov ecx, cardWidth
      call Gotoxy
Bottom:
      call WriteChar
      Loop Bottom
      mov al, '|'
      mov ecx, cardHeight
Left:
      call Gotoxy
      sub dh, 1
      call WriteChar
      Loop Left
      mov ecx, cardHeight
      add dl, cardWidth
      add dh, 1
Right:
      call Gotoxy
      call WriteChar
      add dh, 1
      Loop Right


      mov edx, ebx
      inc dh
      inc dl
      mov eax, black + (black*16)
      call SetTextColor
      call Gotoxy
      mov ah, 0
L1:
      mov ecx, cardWidth-1
      call Gotoxy
L2:
      call WriteChar
      Loop L2
      inc ah
      inc dh
      cmp ah, cardHeight-1
      Jb L1

      mov eax, white + (black*16)
      call SetTextColor
      mov edx, ebx
      add dh, cardHeight/2
      add dl, cardWidth/2
      call Gotoxy
      mov al, card
      call WriteChar
      ret
showcard ENDP

;----------------------------------------------------
eval PROC uses eax
;The eval procedure takes the offest of a hand in eax
;and updates its value
;----------------------------------------------------
      mov numAces,0
      movzx edx, BYTE PTR [eax+11]
      mov ecx, 0
      mov BYTE PTR [eax+10],0
a:
      .IF BYTE PTR [eax+ecx]=='2'
            add BYTE PTR[eax+10],2
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='3'
            add BYTE PTR[eax+10],3
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='4'
            add BYTE PTR[eax+10],4
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='5'
            add BYTE PTR[eax+10],5
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='6'
            add BYTE PTR[eax+10],6
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='7'
            add BYTE PTR[eax+10],7
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='8'
            add BYTE PTR[eax+10],8
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='9'
            add BYTE PTR[eax+10],9
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='T'||BYTE PTR [eax+ecx]=='J'||BYTE PTR
[eax+ecx]=='Q'||BYTE PTR [eax+ecx]=='K'
            add BYTE PTR[eax+10],10
      .ENDIF
      .IF BYTE PTR [eax+ecx]=='A'
            inc numAces
      .ENDIF
      inc ecx
      cmp ecx,edx
      jb a

;Used when there is one or more ace in the hand to calculate the score
      movzx ecx, numAces
      .IF ecx > 0
Aces:
      .IF BYTE PTR [eax+10] > 10
            add BYTE PTR [eax+10],1
      .ELSE
            add BYTE PTR [eax+10],11
      .ENDIF
      loop Aces
      .ENDIF

      ret
eval ENDP

END main

