.data
    msg_input:  .asciiz "Ingrese un numero entero positivo n: "
    msg_result: .asciiz "La paridad es: "
    msg_nl:     .asciiz "\n"

.text
.globl main

main:

    # Imprimir el mensaje para solicitar 'n'
    li $v0, 4
    la $a0, msg_input
    syscall

    # Leer el entero 'n' ingresado por el usuario
    li $v0, 5
    syscall
    move $a0, $v0       # Pasamos 'n' al registro de argumento $a0 para la funcion

    # Llamar a la funcion recursiva 'paridad'
    jal paridad
    
    # Guardar el resultado (que viene en $v0) en $t0 para no perderlo al imprimir texto
    move $t0, $v0       

    # Imprimir el mensaje de resultado
    li $v0, 4
    la $a0, msg_result
    syscall

    # Imprimir el valor del resultado (0 o 1)
    li $v0, 1
    move $a0, $t0
    syscall

    # Imprimir salto de linea para limpieza en la consola
    li $v0, 4
    la $a0, msg_nl
    syscall

    # Finalizar el programa correctamente
    li $v0, 10
    syscall


# ------------------------------------------------------------------
# FUNCION: paridad
# Argumentos: $a0 = n (numero entero positivo)
# Retorno:    $v0 = paridad(n)
# ------------------------------------------------------------------
paridad:

    # Reservamos espacio en la pila para 2 variables (8 bytes en total)
    addi $sp, $sp, -8   
    sw   $ra, 4($sp)    # Guardamos $ra (Direccion de retorno para saber a donde volver)
    sw   $a0, 0($sp)    # Guardamos $a0 (El valor actual de 'n')

    # --- CASO BASE ---
    # Si n == 0, saltamos a la etiqueta 'base_case'
    beq  $a0, $zero, base_case

    # --- CASO RECURSIVO (n > 0) ---
    addi $a0, $a0, -1   # Restamos 1 a 'n' ($a0 = n - 1)
    jal  paridad        # Llamada recursiva: paridad(n-1)
    
    # Cuando regresa de la recursividad, el resultado de paridad(n-1) esta en $v0.
    # Ahora aplicamos la formula: 1 - paridad(n-1)
    li   $t0, 1         # Cargamos un 1 en el registro temporal $t0
    sub  $v0, $t0, $v0  # $v0 = 1 - $v0 
    
    j    end_paridad    # Saltamos directo al epilogo para no ejecutar el caso base

base_case:
    # Si entramos aqui, n = 0, por lo tanto paridad(0) = 0
    li   $v0, 0         # Guardamos 0 en el registro de retorno

end_paridad:
    # --- EPILOGO DE LA FUNCION (Restaurar la pila) ---
    lw   $ra, 4($sp)    # Restauramos la direccion de retorno original de este nivel
    lw   $a0, 0($sp)    # Restauramos el valor de 'n' original de este nivel
    addi $sp, $sp, 8    # Liberamos los 8 bytes de la pila devolviendo el puntero

    jr   $ra            # Saltamos de regreso (al 'main' o a la llamada recursiva anterior)