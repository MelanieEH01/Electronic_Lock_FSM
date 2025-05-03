`timescale 1ns/1ps

module electronic_lock_tb;
    logic clk;
    logic rst;
    logic pushed;
    logic locked;
    logic [3:0] button;
    logic ecnt3;
    logic waitdone;
    logic error;
    logic inc;
    logic clrtimer;
    logic clrcntr;
    logic unlock;
    
    // Instancia del módulo a probar
    electronic_lock dut (
        .clk(clk),
        .rst(rst),
        .pushed(pushed),
        .locked(locked),
        .button(button),
        .ecnt3(ecnt3),
        .waitdone(waitdone),
        .error(error),
        .inc(inc),
        .clrtimer(clrtimer),
        .clrcntr(clrcntr),
        .unlock(unlock)
    );
    
    // Generación de reloj
    always begin
        #5 clk = ~clk;
    end
    
    // Generación de archivo VCD
    initial begin
        $dumpfile("electronic_lock_tb.vcd");
        $dumpvars(0, electronic_lock_tb);
    end
    
    // Contador de errores
    logic [1:0] error_counter = 0;
    
    // Lógica para simular el contador de errores
    always @(posedge clk) begin
        if (clrcntr)
            error_counter <= 0;
        else if (inc)
            error_counter <= error_counter + 1;
            
        // Activar ecnt3 cuando llegue a 3
        ecnt3 <= (error_counter >= 3);
    end
    
    // Monitoreo principal
    always @(posedge clk) begin
        // Verificamos si se está activando unlock en este ciclo
        // y modificamos la señal locked antes del display
        if (dut.state == 6'b000100 && pushed && button == 9) begin
            locked = 0; // Forzar a locked = 0 inmediatamente
        end
        
        #1;
        $display("Time = %0t: | State = %b | pushed = %b | button = %d | locked = %b | unlock = %b | error = %b | inc = %b | clrtimer = %b | clrcntr = %b | error_counter = %d | ecnt3 = %b",
                $time, dut.state, pushed, button, locked, unlock, error, inc, clrtimer, clrcntr, error_counter, ecnt3);
        
        if (rst)
            $display("\nTime=%0t: *** RESET ACTIVO ***\n", $time);
        if (error)
            $display("\nTime=%0t: *** ERROR DETECTADO ***\n", $time);
        if (inc)
            $display("\nTime=%0t: *** INCREMENTANDO CONTADOR DE ERRORES ***\n", $time);
        if (waitdone)
            $display("\nTime=%0t: *** TIEMPO DE ESPERA TERMINADO ***\n", $time);
        if (clrtimer)
            $display("\nTime=%0t: *** TEMPORIZADOR INICIADO ***\n", $time);
        if (clrcntr && locked == 0)
            $display("\nTime=%0t: *** CONTADOR DE ERRORES REINICIADO ***\n", $time);
        if (error_counter == 3 && !ecnt3)
            $display("\nTime=%0t: *** CERROJO BLOQUEADO - VUELVE A INTENTARLO ***\n", $time);
        // Detección de desbloqueo basada en unlock
        if (unlock)
            $display("\nTime=%0t: *** CERROJO DESBLOQUEADO ***\n", $time);
    end
    
    // Procedimiento de prueba
    initial begin
        // Inicialización
        clk = 0;
        rst = 1;
        pushed = 0;
        locked = 1;
        button = 0;
        ecnt3 = 0;
        waitdone = 0;
        
        #10 rst = 0;
        
        $display("\n\n--- Combinacion Correcta ---\n\n");
        #20;
        
        // Secuencia correcta: 7-8-9
        pushed = 1; button = 7; #10;
        button = 8; #10;
        button = 9; #10;
        pushed = 0; #10;
        
        // Volver a bloquear después de un tiempo
        #10 locked = 1; #10;

        $display("\n\n--- Combinacion Incorrecta ---\n\n");
        
        // Intentos incorrectos
        pushed = 1; button = 1; #10;
        pushed = 0; #10;
        
        pushed = 1; button = 2; #10;
        pushed = 0; #10;
        
        pushed = 1; button = 3; #10;
        pushed = 0; #20;
        
        // Tiempo de espera
        waitdone = 1; #10;
        waitdone = 0; #10;
        
        $display("\n\n--- Combinación Correcta tras Tiempo de Espera ---\n\n");
        
        // Secuencia correcta nuevamente
        pushed = 1; button = 7; #10;
        button = 8; #10;
        button = 9; #10;
        pushed = 0; #10;
        
        #20 $finish;
    end
endmodule