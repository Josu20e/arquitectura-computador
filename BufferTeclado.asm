# ==============================================================================
# Ejercicio 1: Buffer de Teclado con Filtro (Interrupciones y Temporizador)
# ==============================================================================

.data
    # Variables del programa principal (Modo Usuario)
    buffer:      .space 64      # Espacio para el buffer circular (64 bytes)
    buf_idx:     .word 0        # Índice de inserción actual
    msg_timer:   .asciiz "\n[!] 20s transcurridos. Contenido del Buffer: "
    msg_nl:      .asciiz "\n"

# Variables reservadas para el Kernel (Rutina de Interrupción)
.kdata
    save_at:     .word 0
    save_t0:     .word 0
    save_t1:     .word 0

.text
.globl main

main:
    # 1. Habilitar interrupciones en el procesador (Coprocesador 0)
    mfc0 $t0, $12           # Leer registro Status
    ori  $t0, $t0, 0x0801   # Habilitar IE (bit 0) y máscara de hardware (bit 11)
    mtc0 $t0, $12           # Guardar configuración

    # 2. Habilitar interrupciones en el hardware del teclado
    li   $t0, 0xFFFF0000    # Dirección de Control del Teclado
    li   $t1, 2             # Bit 1 = Interrupt Enable
    sw   $t1, 0($t0)

loop_principal:
    # Obtener el tiempo de inicio (Syscall 30 devuelve ms en $a0)
    li   $v0, 30
    syscall
    move $s0, $a0           # Guardar marca de tiempo inicial

loop_espera:
    # Obtener tiempo actual y comparar
    li   $v0, 30
    syscall
    subu $t0, $a0, $s0      # $t0 = tiempo actual - tiempo inicial
    
    # 20 segundos = 20000 milisegundos
    li   $t1, 20000
    bgeu $t0, $t1, imprimir_buffer
    
    # Pausa de 50ms (Syscall 32) para no saturar el simulador
    li   $v0, 32
    li   $a0, 50
    syscall
    
    j loop_espera           # Seguir esperando

imprimir_buffer:
    # Imprimir mensaje de notificación
    li   $v0, 4
    la   $a0, msg_timer
    syscall

    # Asegurar terminación nula en la posición actual para imprimir como string
    la   $t0, buf_idx
    lw   $t1, 0($t0)
    la   $t2, buffer
    add  $t3, $t2, $t1
    sb   $zero, 0($t3)      # Insertar NULL (\0) temporal
    
    # Imprimir el buffer
    li   $v0, 4
    move $a0, $t2
    syscall

    # Reiniciar el índice a 0 para el siguiente ciclo
    sw   $zero, 0($t0)
    
    j loop_principal


# ==============================================================================
# RUTINA DE SERVICIO DE INTERRUPCIÓN (ISR)
# Mapeada obligatoriamente en la dirección 0x80000180
# ==============================================================================
.ktext 0x80000180
    # --- PROLOGO: GUARDAR CONTEXTO ---
    # Desactivamos temporalmente el uso de $at por parte del ensamblador
    .set noat
    sw   $at, save_at
    .set at
    sw   $t0, save_t0
    sw   $t1, save_t1

    # --- VERIFICACIÓN DEL HARDWARE ---
    li   $t0, 0xFFFF0000    # Control del teclado
    lw   $t1, 0($t0)
    andi $t1, $t1, 1        # Verificar bit 0 (Ready bit)
    beq  $t1, $zero, fin_interrupcion

    # Leer el caracter (esto limpia la interrupción automáticamente)
    li   $t0, 0xFFFF0004    # Data del teclado
    lw   $t1, 0($t0)        # $t1 = código ASCII ingresado

    # --- FILTRO DE CARACTERES (Solo A-Z) ---
    blt  $t1, 65, fin_interrupcion  # Si es menor a 'A' (65), ignorar
    bgt  $t1, 90, fin_interrupcion  # Si es mayor a 'Z' (90), ignorar

    # --- LÓGICA DEL BUFFER CIRCULAR ---
    la   $t0, buf_idx
    lw   $at, 0($t0)        # Cargar índice actual
    
    la   $t0, buffer
    add  $t0, $t0, $at      # $t0 = dirección base + índice
    sb   $t1, 0($t0)        # Guardar la letra válida
    
    # Incrementar índice con lógica circular: indice = (indice + 1) % 64
    addi $at, $at, 1
    andi $at, $at, 63       # 63 en binario es 00111111 (Módulo 64 rápido)
    
    la   $t0, buf_idx
    sw   $at, 0($t0)        # Guardar el nuevo índice

fin_interrupcion:
    # --- EPILOGO: RESTAURAR CONTEXTO ---
    lw   $t1, save_t1
    lw   $t0, save_t0
    .set noat
    lw   $at, save_at
    .set at
    
    # Retornar de la excepción (Exception Return)
    eret