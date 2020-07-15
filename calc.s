%macro convertor 1
    mov edx,%1
    cmp edx,0x39            ;comparing the input to 9
    jle %%num_value

    sub edx,0x37            ;case A-F
    jmp %%endmac

%%num_value:
    sub edx,0x30
    jmp %%endmac

%%endmac:
%endmacro

%macro deconvert 1
  mov bl,%1  
  add bl, 0x30          ;add '0' to input
  cmp bl, 0x3A          ;if it is a letter add another 7
  jl %%end_deconvert
  add bl, 7
  %%end_deconvert:
%endmacro

%macro delete_list 1
    pushad              
    pushfd
    mov eax,%1             ;save the link address in eax
    %%delete_loop:
    mov dword ebx,[eax+1] ;save next node
    pushad                  
    pushfd
    push eax
    call free              ;push current node and free its memory
    add esp,4              ;clean stack after func call
    popfd
    popad
    mov eax, ebx           ;make ebx point on next node
    cmp eax,0              ;check if we finshed our list
    jne %%delete_loop
    popfd
    popad
%endmacro

%macro Add_List_num 2
    mov edx,0                   ;init edx
    mov ebx, %1                 ;make ebx to point on lsb of list
    mov dl, %2                  ;insert the number we add to dl
 %%plus_loop_1_OP:
    cmp edx,0                   ;check if we have nothing to add to the list
    je %%end_List_num           
    add byte [ebx],dl           ;add edx which is the number to add on first iteration and the carry on all the others to ebx
    mov byte dl,[ebx]           ;move the result to edx
    and byte [ebx],15           ;mask the data inside node to eliminate carry
    shr dl,4                    ;shift right to leave only the carry inside edx 
    cmp dl,0                    ;check if we have carry
    je %%end_List_num           ;if not, end the addition
    mov dword ecx,ebx           ;else save the current node in ecx
    mov dword ebx,[ebx+1]       ;move ebx to point on next link
    cmp ebx,0                   ;check if next link is empty
    jne %%plus_loop_1_OP        ;if not, continue addition loop
    mov ebx,ecx                 ;else return ebx to point to current link
    Create_Node                 ;create a new node
    mov dword [ebx+1],eax       ;make ebx to point next on new node
    mov byte [eax],dl           ;make the data of new node be the carry
    %%end_List_num:
%endmacro

%macro Create_Node 0 
    pushad
    pushfd
    push 5                              ;size of each node
    call malloc                 
    add esp,4                                               
    mov dword [temp_node], eax          ;save new node in a global var
    popfd               
    popad
    mov eax,[temp_node]                 ;return new node to eax
    mov byte [eax],0                    ;init data to 0
    mov dword [eax+1],0                 ;init next data pointer to 0
    mov dword [temp_node],0             ;zero temp pointer
%endmacro

%macro print_list 2
    mov eax,%1              ;make eax point on current link
    %%print_loop:   
    mov bl,[eax]            ;make bl have the data of curr link
    deconvert bl            ;get char representation of the data (will be returned to bl)
    mov byte [to_print], bl ;put the char inside an output buffer
    pushad      
    pushfd
    mov eax, 4
    mov ebx, %2                 ;poniter for output buffer (1 for stdout 2 for stderr)
    mov ecx, to_print
    mov edx,1
    int 0x80                   ;sys_write to output the Char
    popfd
    popad 
    mov dword eax, [eax+1]      ;make eax point next
    cmp eax, 0                  ;check if we reach the end of loop
    jne %%print_loop            ;if not continue looping
    mov byte [to_print], 10
    mov eax, 4
    mov ebx, %2
    mov ecx, to_print
    mov edx,1
    int 0x80                    ;print \n to end line

%endmacro

%macro print_error 1
    push %1                     ;push error message
    call printf                 
    add esp,4
%endmacro

%macro Pow_checks 0
    cmp byte [index],2                  ;check if we have enough args 
    jnl %%Y_check                       ;if we do check the Y argument
    print_error stack_error             ;else print error
    jmp menu_loop
    %%Y_check:                          
    my_pop                              
    push eax                              ;pop our stack and push top list to program stack 
    my_pop
    mov ebx,eax                           ;pop our stack and make ebx to have it's pointer
    push ebx                                    
    mov edx,0                             ;init edx
    mov ecx,0                             ;init ecx
    add byte dl,[ebx]                     ;add edx the data inside Y list first link
    cmp dword [ebx+1],0                   ;check if Y has one more link
    je %%No_pows_Error
    mov dword ebx,[ebx+1]                 ;if not make ebx point to next
    mov byte cl,[ebx]                     ;make ecx have the next digit
    shl cl,4                              ;make room for new digit
    add edx,ecx                           ;add data
    cmp edx,0xC8                          ;compare to 200
    jg %%Pows_error                       ;if it is greater we have an error
    cmp dword [ebx+1],0                   ;else we check if have a next link
    je %%No_pows_Error                    ;if not than edx has our correct Y
    %%Pows_error:
    pop ebx                               ;pop from stack point to first link of y                        
    my_push ebx                           ;and push it to our stack
    pop ecx                               ;pop from stack point to first link of x
    my_push ecx                           ;and push it to our stack
    print_error power_error
    jmp menu_loop
    %%No_pows_Error:
    pop ebx                               ;pop from stack point to first link of y 
    delete_list ebx                       ;and delete the list since we have the data in edx
    pop ecx                               ;pop from stack point to first link of x
    my_push ecx                           ;and push it to our stack (we will work on the list using the adress in ecx)
%endmacro

%macro my_push 1
    pushad
    pushfd
    mov edx ,%1
    push 6
    push edx
    push push_msg
    call debug_print                    ;call debug print with arguments message, link to the linked list and message length
    add esp,12
    mov eax,0                           ;init eax
    mov byte al,[index]                 ;make eax have index to current free space
    mov dword [machsanit+4*eax],edx     ;put list in the space
    inc byte [index]                    ;add 1 to index
    popfd
    popad
%endmacro

%macro my_pop 0
    pushad
    pushfd
    mov eax,0                           ;init eax
    mov byte al,[index]                 ;make eax have index to current free space
    dec al                              ;the index of the top number in the stack
    mov dword ebx ,[machsanit+4*eax]    ;the top number in the stack
    mov dword [temp_node],ebx
    mov dword [machsanit+4*eax],0       ;cleaning the top number
    mov [index],al
    popfd
    popad
    mov dword eax,[temp_node]           ;eax now hold the number that was in the top of the stack
    mov dword [temp_node],0
    push 5
    push eax
    push pop_msg
    call debug_print                     ;call debug print with arguments message, link to the linked list and message length
    add esp,12
%endmacro


section .rodata
  format_string: db "%X",10,0    ;format string for decimal
  op_error: db 'Error: Operand Stack Overflow',10,0
  stack_error: db 'Error: Insufficient Number of Arguments on Stack',10,0
  calc: db 'calc: ',0
  push_msg: db 'push: ',0
  pop_msg: db 'pop: ',0
  power_error: db 'wrong Y value',10,0

section .bss
   input: resb 81
   input_length: resb 1
   machsanit: resd 5 
   converted: resb 1
   to_print:resb 1
   
  
section .data
    index db 0
    looping db 0
    temp_node dd 0
    debug db 0

section .text
    align 16
    global main
    global menu 
    extern printf 
    extern malloc 
    extern free 
    extern stdin

main:
    mov ecx,[esp+4]             ;save in ecx argc
    mov eax,0                   ;init eax
    mov ebx,[esp+8]             ;make ebx to point to argv[0]
    debug_loop:
    cmp eax,ecx                 ;check if we reached the end of arguments loop
    je end_search               
    mov edx,[ebx]               ;mov argv[i][0] to edx
    inc eax                     ;add 1 to eax
    add ebx,4                   ;ebx = argv[i+1]
    cmp word [edx],0x642d       ;compare argv[i] to -d in little endian
    jne debug_loop              ;if not equals try again
    mov byte [debug],1          ;if equals, change debug flag to 1
    end_search:
    call menu
    push eax
    push format_string
    call printf
    add esp,8
    mov eax,1
    mov ebx,0
    int 0x80

menu:
    push ebp
    mov ebp,esp
    sub esp,4                       ;make space for local var - num of operations counter
    mov dword [ebp-4],0  ;init operation counter
    menu_loop:
    
    mov ecx,80                
    clear_loop:          ;input buffer cleaning that runs 80 times
        mov byte [input +ecx],0
        dec ecx
        cmp ecx,-1
        jne clear_loop
    
    inc dword [ebp-4]    ;add one operation to count            XXXXXXXXXXXXXXXXXXXXXXXXx
    mov edx,7
    mov ecx,calc
    mov ebx,1
    mov eax,4
    int 0x80                ;print calc: 

    mov edx,81              ;max reading length
    mov ecx,input           ;where to store the reading operation
    mov ebx,0               ;from where to read
    mov eax,3               ;to perform reading
    int 0x80                ;system call - we use it since it returns the actual input length
    sub eax,1               ;reduce the "\n" in the end of the input
    mov [input_length],al  ;saving the input_length that returns from the read system call
    mov byte [looping], 0  ;init an index that points to current char in input
    cmp byte [input],113   ;equal to q
    je ending
    cmp byte [input],43    ;equal to +
    jne check_print
    call plus
    jmp menu_loop
    check_print:
    cmp byte [input],112   ;equal to p
    jne check_dup
    jmp pop_Nprint
    check_dup:
    cmp byte [input],100   ;equal to d
    jne check_pow
    call duplicate
    jmp menu_loop
    check_pow:
    cmp byte [input],94    ;equal to ^
    jne check_min_pow
    je power
    check_min_pow:
    cmp byte [input],118   ;equal to v
    je min_power
    cmp byte [input],110   ;equal to n
    je num_of_ones
    dec dword [ebp-4]       ; in case the input is a number

                            ;ELSE the input is number
    mov byte cl,[input_length]  ;save the length in ecx to be able to do looping over the input
    cmp byte [index], 4
    jle unpad_zeros
    print_error op_error
    jmp menu_loop
    mov ebx,0
    unpad_zeros:            ;in case that the input is number that starts with zeroes
    mov edx,0
    mov dl, [input+ebx]
    cmp dl, 0x30            ;is the first digit is equal to 0?
    jg make_input           ;if not then jump to continue the procedure
    inc byte [looping]
    dec cl                  ;dec the input length
    inc ebx                 ;go to the next digit
    cmp cl,1                ;check if the number is 'real'
    jnl unpad_zeros          ;keep checking
    Create_Node
    my_push eax                 
    jmp menu_loop
make_input:
push dword 0     
input_loop: 
    mov ebx,0                            ;looping over the input 
    mov bl,[input_length]              ;put saved input length in ebx (we will later use ebx so we save it each time)
    sub bl,cl
    add dword ebx,input
    mov dl,[ebx]            
    and edx,255
    convertor edx                       ;convert our next digit
    pop ebx
    Create_Node
    push eax
    mov byte [eax],dl                   ;saving the data of the link in the right place in the link (after converting the data)
    mov dword [eax+1], ebx              ;put the linker in the link to point the previous link
    inc byte [looping]                  ;input index + 1
    mov ecx,0                        
    mov byte cl,[input_length]        
    sub ecx,[looping]
    cmp ecx,1                           ;we check if we reached the end of the used input buffer 
    jnl input_loop                      ;if not we continue 
    pop eax
    my_push eax
    jmp menu_loop                     
plus:
    push ebp
    mov ebp,esp
    cmp byte [index],2                  ;check if there are at least 2 elements in the stack               
    jnl No_plus_error
    print_error stack_error
    jmp return_plus
    No_plus_error:
    my_pop
    mov ecx, eax                        ;ecx pointing to the top list
    push ecx
    my_pop                             
    mov ebx, eax                        ;ebx pointing to the bottom list
    mov edx,0                           ;init edx to 0 - it represents our carry inside the loop
    push ebx                            ;push pointer to stack so we will return it in the end to our stack
    plus_loop_2_OP:
    add byte dl,[ecx]                   ;add the data inside top list to carry
    add byte [ebx],dl                   ;add carry + top list data to bottom list
    mov byte dl,[ebx]                   ;move the sum to edx
    and byte [ebx],15                   ;mask the data in top list to remove carry
    shr dl,4                            ;shift carry to be at the right half of our carry byte
    mov eax,0                           ;init eax to 0
    add dword eax,[ebx+1]               ;add the pointer value to next node in bottom list to eax
    add dword eax,[ecx+1]               ;add the pointer value to next node in top list to eax
    cmp eax,0                           ;compare eax to 0 because equality means both lists have reached their end
    je carry_add                        ;if we ended iterating our lists we still might have carry
    cmp dword [ecx+1],0                 ;else we check if we only ended the top list
    je plus_loop_1_OP                   ;if so we only add carry to the remaining of top list
    cmp dword [ebx+1],0                 ;else we check if we ended at least the bottom list
    je add_tail                         ;if so we need to make the tale of top list be the tail of bottom list
    mov dword ebx,[ebx+1]               ;else both have not ended 
    mov dword ecx,[ecx+1]               ;so we make each pointer point on next node
    jmp plus_loop_2_OP                  ;and return to the start of the loop
    add_tail:                           ;in this label we have finished the list save in ebx but not ecx
    mov dword eax,[ecx+1]               ;so we move to eax the pointer to ecx.next
    mov dword [ebx+1],eax               ;then we make ebx.next be ecx.next
    mov dword [ecx+1],0                 ;and we change ecx.next to be 0 so when we free the lists memory it will end here
    plus_loop_1_OP:                     ;loop for adding 1 operand list and the carry
    mov dword ebx,[ebx+1]               ;make ebx point ebx.next
    cmp edx,0                           ;compare carry to 0 
    je end_plus                         ;if it is 0 it means the addition is over
    add byte [ebx],dl                   ;else we add the carry
    mov byte dl,[ebx]                   ;move the sum to edx
    and byte [ebx],15                   ;mask the data in top list to remove carry
    shr dl,4                            ;shift carry to be at the right half of our carry byte
    carry_add:                          
    cmp dl,0                            ;compare carry to 0 
    je end_plus                         ;if it is 0 it means the addition is over
    cmp dword [ebx+1],0                 ;check if we have next
    jne plus_loop_1_OP                  ;if so then we continue the loop
    Create_Node                         ;else we create a new node
    mov dword [ebx+1],eax               ;we make our list to point on it
    mov byte [eax],dl                   ;we move the carry to be its data      
    end_plus:
    pop ebx                             ;we pop the first node of our result list 
    my_push ebx                         ;push result to our stack
    pop ebx                             ;now we pop the second operand pointer
    delete_list ebx                     ;and delete the whole list (excluding the part which was moved to result list)
    return_plus:
    mov esp,ebp
    pop ebp
    ret

pop_Nprint:
cmp byte [index],0
jne No_Print_error
print_error stack_error                 ;there is no number in the stack
jmp menu_loop
No_Print_error:
my_pop                                  ;the top number is now in eax
mov ebx,eax                                
mov eax,0                               ;in case we will reverse the list eax will be prev
mov dword ecx, [ebx+1]                  ;ecx pointing to the next link
cmp ecx,0                               ;if ecx=0 then it means that the last link was in ebx (and the 'null' link is in ecx)
je print                                ;so we move to the print part  
reverse_list_loop:                      ;else we need to reverse the list to big endian
    mov [ebx+1], eax                    ;mov current.next to be prev
    mov eax,ebx                         ;make prev be curr
    mov ebx,ecx                         ;mov curr to be next
    mov dword ecx,[ecx+1]               ;mov next to be new_curr.next
    cmp ecx,0                           ;check if we finished the loop
    jne reverse_list_loop
    mov dword [ebx+1],eax               ;if we finished the loop just make the final change
    print:                              
    push ebx                            ;save the current link in eax
    print_list ebx, 1                      ;print the list
    pop ebx                             ;get back pointer to first
    delete_list ebx                     ;release memory                           
    jmp menu_loop

duplicate:
    push ebp                              
    mov ebp,esp
    cmp byte [index],5                    ;check if the stack is already full
    jne Not_Full_stack_duplicate          ;if we have place then continue checks
    print_error op_error                  ;else print error
    jmp end_dup                           ;and return
    Not_Full_stack_duplicate:             ;label that checks stack not empty
    cmp byte [index],0
    jne NO_Duplicate_Error                ;if not empty we can duplicate
    print_error stack_error               ;else print error
    jmp end_dup                           ;and return 
    NO_Duplicate_Error:
    my_pop                                ;pop top list
    my_push eax                           ;and push it back in
    mov dword ecx, eax                    ;move ecx to have pointer for current ndeo
    Create_Node
    push eax                              ;push new node to stack
    mov byte bl, [ecx]                    ;move cuur.data to bl
    mov byte [eax] ,bl                    ;move bl to new_node.data
    mov dword ecx ,[ecx+1]                ;curr = curr.next
    mov edx,eax                           ;edx has pointer to new link
    duplicate_loop:
    cmp ecx, 0                            ;check if we endedv the duplication
    je return_dup
    Create_Node                           
    mov dword [edx+1],eax                 ;make new node be the next of last duplication created
    mov byte bl,[ecx]                     ;move cuur.data to bl
    mov byte [eax],bl                     ;move bl to new_node.data
    mov edx,eax                           ;edx has pointer to new link
    mov dword ecx,[ecx+1]                 ;curr = curr.next 
    jmp duplicate_loop
    return_dup:
    pop eax                               ;pop new list first node
    my_push eax                           ;and push it to our stack
    end_dup:
    mov esp,ebp
    pop ebp
    ret

power:
    Pow_checks              ;if we passed this so it means that we had at least 2 numbers in the stack
    Pow_loop:               ;and Y<200
        cmp edx,0           ;edx has Y value so we iterate Y times
        je menu_loop
        pushad
        pushfd
        call duplicate      ;each time we dupilicate current X
        call plus           ;and add it with itself
        popfd
        popad
        dec edx
        jmp Pow_loop

min_power:
    Pow_checks              ;if we passed this so it means that we had at least 2 numbers in the stack
    min_pow_loop:           ;and Y<200            
    cmp edx,0               ;edx has Y value so we iterate Y times
    je menu_loop            ;if Y is 0 we have no changes to do
    my_pop                  ;remove X from stack
    cmp edx,4               ;check if Y is more than 4
    jl less_than_4     
    mov ebx,ecx             ;else ecx has curr X pointer and now ebx also 
    mov dword ecx,[ecx+1]   ;make ecx point to curr.next
    mov dword [ebx+1],0     ;set curr.next to be 0
    delete_list ebx         ;end delete current node
    sub edx,4               ;Y=Y-4
    cmp ecx,0               ;check if we have a list left
    jne not_empty           
    Create_Node             ;if not make a new 0 list 
    my_push eax             ;push it to our stack
    jmp menu_loop           ;and finish the procedure
    not_empty:              
    my_push ecx             ;push new X
    jmp min_pow_loop         
    less_than_4:
    my_push ecx             ;push new X
    less_than_4_loop:
    mov al,dl               ;copy curr Y which is <4 to al
    shift_right_loop:       ;shift right curr data Y times loop
    shr byte [ecx],1
    dec al
    cmp al,0
    jne shift_right_loop
    cmp dword [ecx+1],0        ;check if it was the last node
    je menu_loop               ;if so we have finished
    mov dword ebx,[ecx+1]      ;make ebx point to curr.next
    push ebx                   ;save new curr link in stack
    mov byte bl,[ebx]          ;make bl have curr.data
    mov al,dl                  ;copy curr Y which is <4 to al
    shl bl,4                   ;make shift left next.data to the left 4-Y times
    shift_left_loop:           ;first we shifted left 4 times and now we shift right Y times 
    shr bl,1
    dec al
    cmp al,0
    jne shift_left_loop
    and bl, 0xF                 ;save the result without any carry
    or byte [ecx],bl            ;add to prev the result
    pop ebx                     ;pop prev adress
    cmp dword [ebx+1],0         ;check if we have next
    jne finish_less_than_4_loop ;if so continue the loop
    push ebx                    ;else we check if we have a 0 padding in our new list MSB
    mov al,dl                   ;copy curr Y which is <4 to al
    mov bl,[ebx]                ;make bl have curr.data
    check_pad_loop:             ;we shift next byte Y times right to check later if it has remainder
    shr bl,1
    dec al
    cmp al,0
    jne check_pad_loop          
    cmp bl,0        
    jne pop_ebx                 ;if it is not zero we have nothing to change
    mov dword [ecx+1],0         ;else we we eliminate the link to this list
    pop ebx                     ;we pop the next link
    delete_list ebx             ;delete it
    jmp menu_loop
    pop_ebx:                    ;pop the next link to remove it from the stack
    pop ebx
    finish_less_than_4_loop:
    mov dword ecx,[ecx+1]          ;ecx = curr.next
    jmp less_than_4_loop

num_of_ones:                    ;iterating over the first list , on each number iterat 4 times to count the number of '1'
    cmp byte [index],0
    jg No_n_Error                ;there is at least one number in the stack  
    print_error stack_error     ;there is no number in the stack
    jmp menu_loop
    No_n_Error:
    my_pop                      ;poping the lact number into eax and delete it from the stack
    mov ebx,eax
    push ebx                    ;ebx holding the number that was in the top of the stack
    Create_Node
    num_of_ones_loop:
    cmp ebx,0                   ;check if we finished
    je end_num_of_ones
    mov ecx,0
    mov cl, [ebx]               ;cl holding the acctual number of the link list
    and cl,1                    ;masking to get the lsb
    pushad
    pushfd
    Add_List_num eax, cl
    popfd
    popad
    mov cl, [ebx]               ;just to make sure that cl will hold the number of the link
    shr cl,1
    mov [ebx],cl
    cmp cl,0                    ;check if we fiished with this link 
    jne num_of_ones_loop        ;if not perfom this loop again
    mov dword ebx,[ebx+1]       ;else ebx will hold the next link
    jmp num_of_ones_loop
    end_num_of_ones:
    my_push eax                 ;eax holds the number of '1' in the original number
    pop ebx
    delete_list ebx
    jmp menu_loop

ending:
    free_loop:                  ;a loop that empties the memory for our stack
    cmp byte [index],0
    je end_calc
    my_pop
    delete_list eax         
    jmp free_loop
    end_calc:           
    mov eax,[ebp-4]             ;mov the counter value to eax
    dec eax                     ;decrease the value by one to eliminate the q call
    add esp,4                   ;clean stack
    mov esp,ebp             
    pop ebp
    ret

debug_print:
    push ebp
    mov ebp,esp 
    cmp byte [debug],0          ;check if debug flag is not 0
    je end_debug                ;if it is we skip to end
    pushad
    pushfd
    mov eax,4
    mov ebx,2
    mov ecx,[ebp+8]             ;first arg has debug message
    mov edx,[ebp+16]            ;third one has its length
    int 0x80
    print_list [ebp+12],2       ;second arg has the list and we print it (will be printed as is)
    popfd
    popad
    end_debug:
    mov esp, ebp
    pop ebp
    ret