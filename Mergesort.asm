.data
    # Arreglo de prueba desordenado (8 elementos)
    array:      .word 12, 5, 9, 1, 15, 3, 8, 4
    size:       .word 8
    
    # Arreglo temporal usado para la fase de mezcla (Merge)
    # Reservamos espacio para 8 enteros (32 bytes)
    temp_array: .space 32 
    
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

    # --- LLAMADA A MERGESORT ---
    la $a0, array       # $a0 = Direccion base del arreglo
    li $a1, 0           # $a1 = left (Indice inicial, 0)
    
    lw $t0, size        # Cargamos el tamano del arreglo
    addi $a2, $t0, -1   # $a2 = right (Indice final, size - 1)
    
    jal mergesort       # Ejecutar Mergesort

    # --- IMPRIMIR ARREGLO ORDENADO ---
    li $v0, 4
    la $a0, msg_after
    syscall
    jal print_array

    # --- FIN DEL PROGRAMA ---
    li $v0, 10
    syscall

# ------------------------------------------------------------------
# FUNCION: mergesort
# Parametros: 
#   $a0 = direccion base del arreglo
#   $a1 = left (indice inferior)
#   $a2 = right (indice superior)
# ------------------------------------------------------------------
mergesort:
    # Condicion base: si (left >= right), terminar recursion
    bge $a1, $a2, mergesort_end 

    # Reservar 16 bytes en la pila
    addi $sp, $sp, -16
    sw   $ra, 12($sp)    # Guardar direccion de retorno
    sw   $a1, 8($sp)     # Guardar 'left'
    sw   $a2, 4($sp)     # Guardar 'right'
    
    # --- CALCULAR MITAD (mid = (left + right) / 2) ---
    add  $t0, $a1, $a2   
    srl  $t0, $t0, 1     # Shift Right Logical (Divide entre 2)
    sw   $t0, 0($sp)     # Guardar 'mid' en la pila
    
    # --- RECURSION 1: mergesort(arr, left, mid) ---
    move $a2, $t0        # Nuevo 'right' = mid
    jal mergesort
    
    # --- RECURSION 2: mergesort(arr, mid+1, right) ---
    lw   $t0, 0($sp)     # Cargar 'mid'
    addi $a1, $t0, 1     # Nuevo 'left' = mid + 1
    lw   $a2, 4($sp)     # Restaurar 'right' original
    jal mergesort
    
    # --- MEZCLAR: merge(arr, left, mid, right) ---
    # Preparar argumentos para la funcion merge
    lw   $a1, 8($sp)     # $a1 = left original
    lw   $a2, 0($sp)     # $a2 = mid
    lw   $a3, 4($sp)     # $a3 = right original (Nuevo argumento)
    jal merge
    
    # --- EPILOGO ---
    lw   $ra, 12($sp)    # Restaurar direccion de retorno
    addi $sp, $sp, 16    # Liberar memoria de la pila

mergesort_end:
    jr $ra               # Retornar


# ------------------------------------------------------------------
# FUNCION: merge
# Parametros: 
#   $a0 = arr, $a1 = left, $a2 = mid, $a3 = right
# ------------------------------------------------------------------
merge:
    # Inicializar indices:
    move $t0, $a1        # i = left  (indice para la primera mitad)
    addi $t1, $a2, 1     # j = mid+1 (indice para la segunda mitad)
    move $t2, $a1        # k = left  (indice para el arreglo temporal)
    la   $t3, temp_array # $t3 = direccion base del arreglo temporal

merge_loop:
    # while (i <= mid && j <= right)
    bgt  $t0, $a2, copy_rem_j  # Si i > mid, copiar lo que queda de j
    bgt  $t1, $a3, copy_rem_i  # Si j > right, copiar lo que queda de i

    # Cargar arr[i]
    sll  $t4, $t0, 2     # Offset = i * 4
    add  $t4, $a0, $t4   # Direccion = base + offset
    lw   $t5, 0($t4)     # $t5 = arr[i]

    # Cargar arr[j]
    sll  $t6, $t1, 2     # Offset = j * 4
    add  $t6, $a0, $t6   # Direccion = base + offset
    lw   $t7, 0($t6)     # $t7 = arr[j]

    # if (arr[i] <= arr[j])
    bgt  $t5, $t7, else_j

    # temp[k] = arr[i]
    sll  $t8, $t2, 2
    add  $t8, $t3, $t8
    sw   $t5, 0($t8)
    
    addi $t0, $t0, 1     # i++
    addi $t2, $t2, 1     # k++
    j merge_loop

else_j:
    # temp[k] = arr[j]
    sll  $t8, $t2, 2
    add  $t8, $t3, $t8
    sw   $t7, 0($t8)
    
    addi $t1, $t1, 1     # j++
    addi $t2, $t2, 1     # k++
    j merge_loop

copy_rem_i:
    # while (i <= mid)
    bgt  $t0, $a2, copy_back
    sll  $t4, $t0, 2
    add  $t4, $a0, $t4
    lw   $t5, 0($t4)     # Cargar arr[i]
    
    sll  $t8, $t2, 2
    add  $t8, $t3, $t8
    sw   $t5, 0($t8)     # temp[k] = arr[i]
    
    addi $t0, $t0, 1     # i++
    addi $t2, $t2, 1     # k++
    j copy_rem_i

copy_rem_j:
    # while (j <= right)
    bgt  $t1, $a3, copy_back
    sll  $t6, $t1, 2
    add  $t6, $a0, $t6
    lw   $t7, 0($t6)     # Cargar arr[j]
    
    sll  $t8, $t2, 2
    add  $t8, $t3, $t8
    sw   $t7, 0($t8)     # temp[k] = arr[j]
    
    addi $t1, $t1, 1     # j++
    addi $t2, $t2, 1     # k++
    j copy_rem_j

copy_back:
    # Transferir datos de temp_array de vuelta a array
    move $t2, $a1        # k = left
copy_back_loop:
    bgt  $t2, $a3, end_merge
    
    # Cargar de temp_array
    sll  $t8, $t2, 2
    add  $t9, $t3, $t8
    lw   $t5, 0($t9)
    
    # Guardar en array
    add  $t9, $a0, $t8
    sw   $t5, 0($t9)
    
    addi $t2, $t2, 1     # k++
    j copy_back_loop

end_merge:
    jr $ra               # Retornar


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