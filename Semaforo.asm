# ==============================================================================
# Ejercicio 2: Semáforo con Pulsador (Interrupciones y Temporizador)
# ==============================================================================

.data
    # Variables de estado
    # 0: Verde, 1: Pulsado, 2: Esp. Amarillo, 3: Esp. Rojo, 4: Esp. Verde
    estado:     .word 0     
    tiempo_obj: .word 0     # Marca de tiempo (ms) para la proxima transicion
    
    # Mensajes requeridos[cite: 4]
    msg_verde:  .asciiz "\nSemaforo en verde, esperando pulsador.\n"
    msg_pulso:  .asciiz "\nPulsador activado: en 20 segundos, el semaforo cambiara a amarillo.\n"
    msg_amar:   .asciiz "\nSemaforo en amarillo, en 10 segundos, semaforo en rojo.\n"
    msg_rojo:   .asciiz "\nSemaforo en rojo, en 30 segundos, semaforo en verde.\n"

.kdata
    # Espacio seguro para guardar el contexto
    save_at:    .word 0
    save_t0:    .word 0
    save_t1:    .word 0

.text
.globl main

main:
    # 1. Habilitar interrupciones del Coprocesador 0[cite: 4]
    mfc0 $t0, $12
    ori  $t0, $t0, 0x0801
    mtc0 $t0, $12

    # 2. Habilitar interrupciones de teclado (Keyboard MMIO)[cite: 4]
    li   $t0, 0xFFFF0000
    li   $t1, 2
    sw   $t1, 0($t0)

    # Mostrar estado inicial[cite: 4]
    li   $v0, 4
    la   $a0, msg_verde
    syscall

loop_principal:
    # Leer estado actual
    la   $t0, estado
    lw   $t1, 0($t0)

    beq  $t1, 0, delay         # Estado 0: Esperando pulsador (no evaluar tiempo)
    beq  $t1, 1, transicion_1  # Estado 1: Pulsador presionado
    
    # Estados 2, 3 y 4: Comparar tiempo actual con tiempo_obj
    li   $v0, 30               # Syscall 30: Obtiene tiempo en $a0
    syscall
    
    la   $t2, tiempo_obj
    lw   $t3, 0($t2)
    bltu $a0, $t3, delay       # Si tiempo < tiempo_obj, seguir esperando

    # Tiempos cumplidos: avanzar de estado
    beq  $t1, 2, transicion_2
    beq  $t1, 3, transicion_3
    beq  $t1, 4, transicion_4

delay:
    # Pausa de 50ms para no saturar CPU
    li   $v0, 32
    li   $a0, 50
    syscall
    j    loop_principal

# ---------------------------------------------------------
# TRANSICIONES DE ESTADO
# ---------------------------------------------------------
transicion_1:
    li   $v0, 4
    la   $a0, msg_pulso
    syscall
    
    # Timer: +20 segundos (20000 ms)[cite: 4]
    li   $v0, 30
    syscall
    addu $a0, $a0, 20000
    la   $t2, tiempo_obj
    sw   $a0, 0($t2)
    
    li   $t1, 2
    la   $t0, estado
    sw   $t1, 0($t0)
    j    loop_principal

transicion_2:
    li   $v0, 4
    la   $a0, msg_amar
    syscall
    
    # Timer: +10 segundos (10000 ms)[cite: 4]
    li   $v0, 30
    syscall
    addu $a0, $a0, 10000
    la   $t2, tiempo_obj
    sw   $a0, 0($t2)
    
    li   $t1, 3
    la   $t0, estado
    sw   $t1, 0($t0)
    j    loop_principal

transicion_3:
    li   $v0, 4
    la   $a0, msg_rojo
    syscall
    
    # Timer: +30 segundos (30000 ms)[cite: 4]
    li   $v0, 30
    syscall
    addu $a0, $a0, 30000
    la   $t2, tiempo_obj
    sw   $a0, 0($t2)
    
    li   $t1, 4
    la   $t0, estado
    sw   $t1, 0($t0)
    j    loop_principal

transicion_4:
    li   $v0, 4
    la   $a0, msg_verde
    syscall
    
    # Reiniciar ciclo al Estado 0[cite: 4]
    li   $t1, 0
    la   $t0, estado
    sw   $t1, 0($t0)
    j    loop_principal

# ==============================================================================
# RUTINA DE SERVICIO DE INTERRUPCION (ISR) - Mapeada en 0x80000180
# ==============================================================================
.ktext 0x80000180
    # Guardar contexto de registros
    .set noat
    sw   $at, save_at
    .set at
    sw   $t0, save_t0
    sw   $t1, save_t1

    # Validar interrupcion de teclado
    li   $t0, 0xFFFF0000
    lw   $t1, 0($t0)
    andi $t1, $t1, 1
    beq  $t1, $zero, fin_isr

    # Consumir caracter
    li   $t0, 0xFFFF0004
    lw   $t1, 0($t0)        

    # Verificar si es 's' (115) o 'S' (83)[cite: 4]
    beq  $t1, 115, procesar_s
    beq  $t1, 83, procesar_s
    j    fin_isr

procesar_s:
    # Solo iniciar si el semáforo está en Verde (Estado 0)[cite: 4]
    la   $t0, estado
    lw   $t1, 0($t0)
    bne  $t1, 0, fin_isr

    # Forzar avance al Estado 1
    li   $t1, 1
    sw   $t1, 0($t0)

fin_isr:
    # Restaurar contexto
    lw   $t1, save_t1
    lw   $t0, save_t0
    .set noat
    lw   $at, save_at
    .set at
    
    # Retornar al hilo principal
    eret