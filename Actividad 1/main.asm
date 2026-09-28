.cseg
.org 0x00

.def temp = r16
.def delay_reg = r17

    ; === 1. INICIALIZACIÓN DEL STACK ===
    ; Indispensable para el uso de subrutinas y saltos en la arquitectura AVR
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; === 2. CONFIGURACIÓN DE PUERTOS ===
    ; PB5 como salida, resto como entradas
    ldi temp, 0b0010_0000 
    out DDRB, temp
    
    ; Activa Resistencias pull-up en PB0 y PB1
    ldi temp, 0b0000_0011 
    out PORTB, temp

    ; === 3. CICLO DE SELECCIÓN (POLLING) ===
leer_entradas:
    in temp, PINB
    andi temp, 0b0000_0011 ; Enmascara para evaluar solo PB0 y PB1
    
    cpi temp, 0b0000_0000  
    breq freq_100k
    
    cpi temp, 0b0000_0001  
    breq freq_500k
    
    cpi temp, 0b0000_0010  
    breq freq_1mhz
    
    cpi temp, 0b0000_0011  
    breq freq_2mhz
    
    rjmp leer_entradas

    ; === 4. GENERACIÓN DE FRECUENCIAS (Reloj a 16 MHz) ===

freq_100k: 
    ; 100 kHz -> 160 ciclos por periodo (80 alto / 80 bajo)
    sbi PORTB, 5      ; (2 ciclos)
    ldi delay_reg, 26 ; (1 ciclo)
d100_h: 
    dec delay_reg     ; (1 ciclo)
    brne d100_h       ; (2 ciclos si salta) -> (3 * 26) - 1 = 77 ciclos. Total alto: 80.
    
    cbi PORTB, 5      ; (2 ciclos)
    ldi delay_reg, 23 ; (1 ciclo)
d100_l: 
    dec delay_reg
    brne d100_l       ; Loop consume 68 ciclos
    nop               ; (1 ciclo)
    nop               ; (1 ciclo)
    nop               ; (1 ciclo)
    nop               ; (1 ciclo)
    in temp, PINB     ; (1 ciclo) 
    andi temp, 0x03   ; (1 ciclo)
    cpi temp, 0x00    ; (1 ciclo)
    breq freq_100k    ; (2 ciclos). Total bajo: 2+1+68+4+1+1+1+2 = 80. ¡Exacto!
    rjmp leer_entradas

freq_500k: 
    ; 500 kHz -> 32 ciclos por periodo (16 alto / 16 bajo)
    sbi PORTB, 5      ; (2 ciclos)
    nop \ nop \ nop \ nop \ nop \ nop \ nop 
    nop \ nop \ nop \ nop \ nop \ nop \ nop ; (14 nops). Total alto: 16.
    
    cbi PORTB, 5      ; (2 ciclos)
    nop \ nop \ nop \ nop \ nop \ nop \ nop \ nop \ nop ; (9 nops)
    in temp, PINB     ; (1 ciclo)
    andi temp, 0x03   ; (1 ciclo)
    cpi temp, 0x01    ; (1 ciclo)
    breq freq_500k    ; (2 ciclos). Total bajo: 16. ¡Exacto!
    rjmp leer_entradas

freq_1mhz: 
    ; 1 MHz -> 16 ciclos por periodo (8 alto / 8 bajo)
    sbi PORTB, 5      ; (2 ciclos)
    nop \ nop \ nop \ nop \ nop \ nop ; (6 nops). Total alto: 8.
    
    cbi PORTB, 5      ; (2 ciclos)
    nop               ; (1 ciclo)
    in temp, PINB     ; (1 ciclo)
    andi temp, 0x03   ; (1 ciclo)
    cpi temp, 0x02    ; (1 ciclo)
    breq freq_1mhz    ; (2 ciclos). Total bajo: 8. ¡Exacto!
    rjmp leer_entradas

freq_2mhz: 
    ; 2 MHz -> 8 ciclos por periodo (4 alto / 4 bajo)
    sbi PORTB, 5      ; (2 ciclos)
    nop \ nop         ; (2 nops). Total alto: 4.
    
    cbi PORTB, 5      ; (2 ciclos)
    in temp, PINB     ; (1 ciclo)
    andi temp, 0x03   ; (1 ciclo)
    cpi temp, 0x03    ; (1 ciclo)
    breq freq_2mhz    ; (2 ciclos). Total bajo: 7 ciclos físicos mínimos.
    ; Nota: Es físicamente imposible bajar de 7 ciclos en el estado bajo mientras se leen las entradas.
    rjmp leer_entradas