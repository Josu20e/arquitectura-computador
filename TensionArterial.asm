.data
    # Registros del modulo mapeados en memoria[cite: 3]
    .align 2
    TensionControl: .word 0     
    TensionEstado:  .word 0     
    TensionSistol:  .word 0     
    TensionDiastol: .word 0     

    msg_sis: .asciiz "Tension Sistolica: "
    msg_dia: .asciiz "Tension Diastolica: "
    msg_nl:  .asciiz "\n"

.text
.globl main

main:
    # --- Setup de simulacion en MARS ---
    la $t0, TensionEstado
    li $t1, 1               
    sw $t1, 0($t0)
    
    la $t0, TensionSistol
    li $t1, 120             
    sw $t1, 0($t0)
    
    la $t0, TensionDiastol
    li $t1, 80              
    sw $t1, 0($t0)
    # -----------------------------------

    # Ejecutar el controlador[cite: 3]
    jal controlador_tension

    # Respaldar resultados devueltos en $v0 y $v1[cite: 3]
    move $t0, $v0
    move $t1, $v1

    # Imprimir Sistolica
    li $v0, 4
    la $a0, msg_sis
    syscall
    
    li $v0, 1
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, msg_nl
    syscall

    # Imprimir Diastolica
    li $v0, 4
    la $a0, msg_dia
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, msg_nl
    syscall

    # Fin del programa
    li $v0, 10
    syscall

# ---------------------------------------------------------
# Procedimiento: controlador_tension[cite: 3]
# Retorna: $v0 (Sistolica), $v1 (Diastolica)[cite: 3]
# ---------------------------------------------------------
controlador_tension:
    # 1. Iniciar medicion escribiendo 1 en Control[cite: 3]
    la $t0, TensionControl
    li $t1, 1
    sw $t1, 0($t0)

    # 2. Espera activa (Polling) hasta que Estado sea 1[cite: 3]
    la $t0, TensionEstado
wait_loop:
    lw $t1, 0($t0)
    beq $t1, $zero, wait_loop  

    # 3. Extraer resultados cuando este listo[cite: 3]
    la $t0, TensionSistol
    lw $v0, 0($t0)             # Retorna sistolica en $v0[cite: 3]

    la $t0, TensionDiastol
    lw $v1, 0($t0)             # Retorna diastolica en $v1[cite: 3]

    jr $ra