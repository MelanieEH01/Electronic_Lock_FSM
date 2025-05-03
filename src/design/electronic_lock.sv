module electronic_lock (
    input  logic        clk,
    input  logic        rst,
    input  logic        pushed,    // Indica si se ha pulsado un botón
    input  logic        locked,
    input  logic [3:0]  button,    // Valor del botón pulsado (0-9)
    input  logic        ecnt3,     // Indica si el contador de errores ha llegado a 3
    input  logic        waitdone,  // Indica si el tiempo de espera ha terminado

    output logic        error,     // Salida que indica un error en la combinación
    output logic        inc,       // Incrementa el contador de errores
    output logic        clrtimer,  // Limpia el temporizador
    output logic        clrcntr,   // Limpia el contador de errores
    output logic        unlock     // Desbloquea el cerrojo
);

    // Definición de estados usando One-Hot
    typedef enum logic [5:0] {
        S_A = 6'b000001,  // Start
        S_B = 6'b000010,  // Después de presionar 7
        S_C = 6'b000100,  // Después de presionar 8
        S_D = 6'b001000,  // Desbloqueado (Unlocked)
        S_E = 6'b010000,  // Error
        S_F = 6'b100000   // Espera
    } state_t;
    
    state_t state, next_state;
    logic unlock_reg;
    
    // Registro de estado
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_A;
            unlock_reg <= 0;
        end
        else begin
            state <= next_state;
            if (state == S_C && pushed && button == 9)
                unlock_reg <= 1;
            else
                unlock_reg <= 0;
        end
    end
    
    // Lógica de siguiente estado
    always_comb begin
        // Valor por defecto
        next_state = state;
        
        case (state)
            S_A: begin
                if (pushed && button == 7)
                    next_state = S_B;
                else if (pushed && button != 7)
                    next_state = S_E;
                else
                    next_state = S_A;
            end
            
            S_B: begin
                if (pushed && button == 8)
                    next_state = S_C;
                else if (pushed && button != 8)
                    next_state = S_E;
                else
                    next_state = S_B;
            end
            
            S_C: begin
                if (pushed && button == 9)
                    next_state = S_D;
                else if (pushed && button != 9)
                    next_state = S_E;
                else
                    next_state = S_C;
            end
            
            S_D: begin
                if (locked)
                    next_state = S_A;
                else
                    next_state = S_D;
            end
            
            S_E: begin
                if (ecnt3)
                    next_state = S_F;
                else
                    next_state = S_A;
            end
            
            S_F: begin
                if (waitdone)
                    next_state = S_A;
                else
                    next_state = S_F;
            end
            
            default:
                next_state = S_A;
        endcase
    end
    
    // Lógica de salida
    always_comb begin
        // Asignaciones específicas
        error = (state == S_E);
        inc = error; // Se activa cuando hay error
        clrtimer = (state == S_E && ecnt3);
        clrcntr = (state == S_F && waitdone) || (state == S_D);
        unlock = unlock_reg; // Usar un registro para asegurar que unlock se active
    end

endmodule