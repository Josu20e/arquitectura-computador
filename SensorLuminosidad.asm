.data
    # Registros del sensor mapeados en memoria
    .align 2
    LuzControl: .word 0     
    LuzEstado:  .word 0     
    LuzDatos:   .word 0     

    msg_val:    .asciiz "Luminosidad: "
    msg_err:    .asciiz "Error de hardware en el sensor.\n"

.text
.globl main

main:
    # --- Setup de simulacion en MARS ---
    la $t0, LuzEstado
    li $t1, 1               
    sw $t1, 0($t0)
    la $t0, LuzDatos
    li $t1, 840             
    sw $t1, 0($t0)
    # -----------------------------------

    # 1. Inicializar sensor y esperar[cite: 3]
    jal InicializarSensorLuz

    # 2. Leer estado y datos[cite: 3]
    jal LeerLuminosidad

    # $v0 contiene el estado (0 = OK, 1 = Error)[cite: 3]
    beq $v0, 1, error_hardware

    # Flujo OK: Imprimir dato
    li $v0, 4
    la $a0, msg_val
    syscall

    li $v0, 1
    move $a0, $v1           
    syscall
    
    j fin

error_hardware:
    # Flujo Error: Imprimir alerta
    li $v0, 4
    la $a0, msg_err
    syscall

fin:
    li $v0, 10
    syscall

# ---------------------------------------------------------
# Procedimiento: InicializarSensorLuz[cite: 3]
# ---------------------------------------------------------
InicializarSensorLuz:
    la $t0, LuzControl
    li $t1, 1
    sw $t1, 0($t0)             # Inicializa el sensor escribiendo 0x1[cite: 3]

    la $t0, LuzEstado
wait_loop:
    lw $t1, 0($t0)
    beq $t1, $zero, wait_loop  # Espera activa mientras estado sea 0 (no listo)[cite: 3]
    jr $ra

# ---------------------------------------------------------
# Procedimiento: LeerLuminosidad[cite: 3]
# Retorna: $v0 (Estado: 0=OK, 1=Error), $v1 (Dato)[cite: 3]
# ---------------------------------------------------------
LeerLuminosidad:
    la $t0, LuzEstado
    lw $t1, 0($t0)          

    li $t2, -1
    beq $t1, $t2, set_error    # Verifica si hay error de hardware (-1)[cite: 3]

    # Lectura correcta
    la $t0, LuzDatos
    lw $v1, 0($t0)             # Extrae la lectura de luminosidad[cite: 3]
    li $v0, 0                  # Devuelve codigo de estado 0[cite: 3]
    jr $ra                  

set_error:
    li $v0, 1                  # Devuelve codigo de estado 1 (error)[cite: 3]
    li $v1, 0               
    jr $ra