.data
    # Arreglo de prueba de 8 elementos
    array:      .word 8, 3, 1, 7, 0, 10, 2, 4
    size:       .word 8
    
    # Mensajes para la consola
    msg_before: .asciiz "Arreglo original: "
    msg_after:  .asciiz "Arreglo ordenado: "
    msg_space:  .asciiz " "
    msg_nl:     .asciiz "\n"

.text
.globl main

main:
    # --- IMPRIMIR ARREGLO ORIGINAL ---
    li $v0, 4
    la $a0, msg_before
    syscall
    jal print_array

    # --- LLAMADA A QUICKSORT ---
    la $a0, array       # $a0 = Direccion base del arreglo
    li $a1, 0           # $a1 = low (Indice inicial, 0)
    
    lw $t0, size        # Cargamos el tamaño del arreglo
    addi $a2, $t0, -1   # $a2 = high (Indice final, size - 1)
    
    jal quicksort       # Ejecutar Quicksort

    # --- IMPRIMIR ARREGLO ORDENADO ---
    li $v0, 4
    la $a0, msg_after
    syscall
    jal print_array

    # --- FIN DEL PROGRAMA ---
    li $v0, 10
    syscall

# ------------------------------------------------------------------
# FUNCION: quicksort
# Parametros: 
#   $a0 = direccion base del arreglo
#   $a1 = low (indice inferior)
#   $a2 = high (indice superior)
# ------------------------------------------------------------------
quicksort:
    # Condicion base: si (low >= high), terminar recursion
    bge $a1, $a2, quicksort_end 

    # Reservar 16 bytes en la pila para guardar registros críticos
    addi $sp, $sp, -16
    sw   $ra, 12($sp)    # Guardar direccion de retorno
    sw   $a1, 8($sp)     # Guardar 'low'
    sw   $a2, 4($sp)     # Guardar 'high'
    
    # Llamar a partition(arr, low, high)
    jal partition
    
    # El indice del pivote (pi) retorna en $v0
    sw   $v0, 0($sp)     # Guardar 'pi' en la pila
    
    # --- RECURSION 1: quicksort(arr, low, pi - 1) ---
    lw   $a1, 8($sp)     # Restaurar 'low' original
    lw   $t0, 0($sp)     # Cargar 'pi'
    addi $a2, $t0, -1    # Nuevo 'high' = pi - 1
    jal quicksort
    
    # --- RECURSION 2: quicksort(arr, pi + 1, high) ---
    lw   $t0, 0($sp)     # Cargar 'pi'
    addi $a1, $t0, 1     # Nuevo 'low' = pi + 1
    lw   $a2, 4($sp)     # Restaurar 'high' original
    jal quicksort
    
    # --- EPILOGO ---
    lw   $ra, 12($sp)    # Restaurar direccion de retorno
    addi $sp, $sp, 16    # Liberar memoria de la pila

quicksort_end:
    jr $ra               # Retornar


# ------------------------------------------------------------------
# FUNCION: partition
# Parametros: $a0 = arr, $a1 = low, $a2 = high
# Retorna: $v0 = pi (nuevo indice del pivote)
# ------------------------------------------------------------------
partition:
    # 1. Calcular direccion de arr[high] y definir pivote
    sll $t0, $a2, 2      # $t0 = high * 4 (desplazamiento en bytes)
    add $t0, $a0, $t0    # $t0 = direccion de arr[high]
    lw  $t1, 0($t0)      # $t1 = pivot = arr[high]
    
    addi $t2, $a1, -1    # $t2 = i = low - 1
    move $t3, $a1        # $t3 = j = low

partition_loop:
    # if (j >= high) salir del bucle
    bge $t3, $a2, partition_end 
    
    # Cargar arr[j]
    sll $t4, $t3, 2      # $t4 = j * 4
    add $t4, $a0, $t4    # $t4 = direccion de arr[j]
    lw  $t5, 0($t4)      # $t5 = arr[j]
    
    # if (arr[j] >= pivot) continuar sin intercambiar
    bge $t5, $t1, partition_continue 
    
    # Si arr[j] < pivot, incrementamos 'i' e intercambiamos
    addi $t2, $t2, 1     # i++
    
    # Cargar arr[i]
    sll $t6, $t2, 2      # $t6 = i * 4
    add $t6, $a0, $t6    # $t6 = direccion de arr[i]
    lw  $t7, 0($t6)      # $t7 = arr[i]
    
    # Ejecutar Swap (arr[i] <-> arr[j])
    sw  $t5, 0($t6)      # arr[i] = arr[j]
    sw  $t7, 0($t4)      # arr[j] = antiguo arr[i]

partition_continue:
    addi $t3, $t3, 1     # j++
    j partition_loop     # Repetir ciclo

partition_end:
    # Intercambiar arr[i+1] con el pivote (arr[high])
    addi $t2, $t2, 1     # i = i + 1
    
    sll $t6, $t2, 2      # $t6 = (i+1) * 4
    add $t6, $a0, $t6    # $t6 = direccion de arr[i+1]
    lw  $t7, 0($t6)      # $t7 = arr[i+1]
    
    sw  $t1, 0($t6)      # arr[i+1] = pivot
    sw  $t7, 0($t0)      # arr[high] = antiguo arr[i+1]
    
    # Retornar el indice del pivote (i + 1) en $v0
    move $v0, $t2        
    jr $ra


# ------------------------------------------------------------------
# FUNCION UTILITARIA: print_array
# Imprime todos los elementos del arreglo separados por espacios
# ------------------------------------------------------------------
print_array:
    move $t0, $zero      # $t0 = indice (0)
    lw $t1, size         # $t1 = tamano
    la $t2, array        # $t2 = direccion base

print_loop:
    bge $t0, $t1, print_end # Si indice >= tamano, terminar
    
    # Cargar e imprimir entero
    lw $a0, 0($t2)       
    li $v0, 1            
    syscall
    
    # Imprimir espacio
    la $a0, msg_space
    li $v0, 4
    syscall
    
    # Siguiente elemento
    addi $t0, $t0, 1     # indice++
    addi $t2, $t2, 4     # avanzar 4 bytes en memoria
    j print_loop

print_end:
    # Imprimir salto de linea final
    la $a0, msg_nl
    li $v0, 4
    syscall
    jr $ra