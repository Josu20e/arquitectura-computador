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
    move $a0, $v0       # Pasamos 'n' al registro de argumento $a0

    # Llamar a la funcion iterativa 'paridad_iterativa'
    jal paridad_iterativa
    
    # Guardar el resultado (que viene en $v0) en $t0
    move $t0, $v0       

    # Imprimir el mensaje de resultado
    li $v0, 4
    la $a0, msg_result
    syscall

    # Imprimir el valor del resultado (0 o 1)
    li $v0, 1
    move $a0, $t0
    syscall

    # Imprimir salto de linea
    li $v0, 4
    la $a0, msg_nl
    syscall

    # Finalizar el programa correctamente
    li $v0, 10
    syscall


# ------------------------------------------------------------------
# FUNCION: paridad_iterativa
# Argumentos: $a0 = n (numero entero positivo)
# Retorno:    $v0 = paridad(n)
# Descripcion: Determina la paridad usando un bucle (instrucciones tipo I, J y R)
# ------------------------------------------------------------------
paridad_iterativa:
    # Inicializamos el resultado de la paridad en 0
    li $v0, 0           

loop_paridad:
    # Condicion de salida: Si n == 0, saltamos al final
    beq $a0, $zero, end_iterativa  

    # Alternar la paridad usando la logica: paridad = 1 - paridad
    li $t0, 1           # Cargamos 1 en el temporal $t0
    sub $v0, $t0, $v0   # $v0 = 1 - $v0

    # Disminuir 'n' en 1
    addi $a0, $a0, -1   # $a0 = n - 1

    # Volver a evaluar la condicion al inicio del bucle
    j loop_paridad      

end_iterativa:
    # Retornar al programa principal (la direccion guardada en $ra por 'jal')
    jr $ra