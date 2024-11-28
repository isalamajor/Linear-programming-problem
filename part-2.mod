# Isabel Hernández Barrio (100472315)

###################
# SETS
###################

set AVIONES;      
set PISTAS;        
set SLOTS;    


###################
# PARAMETERS
###################

param hora_programada{AVIONES};       # Hora programada de llegada de cada avión
param hora_limite{AVIONES};            # Hora límite para aterrizar de cada avión
param coste_retraso{AVIONES};          # Coste adicional por minuto de retraso (€)
param disponibilidad{PISTAS, SLOTS} binary;  # Disponibilidad de las pistas para los slots (1 = libre VERDE, 0 = ocupado NEGRO)

param asientos{AVIONES};               # Número de asientos de cada avión
param capacidad{AVIONES};              # Capacidad de equipaje total en cada avión (kg)
param precio_estandar;           # Precio del billete estándar (€)
param precio_leisure;       # Precio del billete leisure plus (€)
param precio_business;      # Precio del billete business plus (€)
param consecutivos{SLOTS, SLOTS} binary; # Variable binaria que indica que dos slots de tiempo son consecutivos o no

###################
# VARIABLES
###################

var asignado{AVIONES, PISTAS, SLOTS} binary; # Variable binaria para asignación

var x_estandar{AVIONES} >= 0, integer;  # Billetes estándar a vender
var x_leisure{AVIONES} >= 0, integer;  # Billetes leisure plus a vender
var x_business{AVIONES} >= 0, integer;  # Billetes business plus a vender

###################
# FUNCIÓN OBJETIVO
###################

# Minimizar el costo de los retrasos y maximizar los ingresos por la venta de billetes
# En definitiva, maximizar el beneficio total
maximize beneficio_total:
    sum{a in AVIONES} (precio_estandar * x_estandar[a] + 
                       precio_leisure * x_leisure[a] + 
                       precio_business * x_business[a]) 
    - sum {a in AVIONES, p in PISTAS, s in SLOTS} coste_retraso[a] * (s - hora_programada[a]) * asignado[a, p, s];

###################
# CONSTRAINTS
###################

# RESTRICCIÓN 1 - Cada avión debe estar asignado a un slot, ni más ni menos
s.t. AvionAsignado {a in AVIONES}:
    sum {p in PISTAS, s in SLOTS} asignado[a, p, s] == 1;

# RESTRICCIÓN 2 - Un slot de tiempo puede ser asignado a un solo avión, puede no estar asignado a ninguno
s.t. SlotAsignado {p in PISTAS, s in SLOTS}:
    sum {a in AVIONES} asignado[a, p, s] <= 1;

# RESTRICCIÓN 3 - El slot asignado debe estar libre 
s.t. SlotValido {a in AVIONES, p in PISTAS, s in SLOTS}:
    asignado[a, p, s] <= disponibilidad[p, s];

# RESTRICCIÓN 4 - El slot de aterrizaje debe ser igual o posterior a la hora de llegada
s.t. SlotTrasLlegada {a in AVIONES, p in PISTAS, s in SLOTS}:
    asignado[a, p, s] * s >= asignado[a, p, s] * hora_programada[a];

# RESTRICCIÓN 5 - El slot de aterrizaje debe ser igual o anterior a la hora límite
s.t. SlotAntesDelLimite {a in AVIONES, p in PISTAS, s in SLOTS}:
    asignado[a, p, s] * s <= asignado[a, p, s] * hora_limite[a];

# RESTRICCIÓN 6 - No se deben asignar dos slots consecutivos en la misma pista 
s.t. SinSlotsConsecutivos {p in PISTAS, s1 in SLOTS, s2 in SLOTS}:
    (sum {a in AVIONES} asignado[a, p, s1] + sum {a in AVIONES} asignado[a, p, s2]) * consecutivos[s1, s2] <= 1;

# RESTRICCIÓN 7 - No vender más billetes que el número de asientos disponibles en cada avión
s.t. LimiteAsientos{a in AVIONES}:
    x_estandar[a] + x_leisure[a] + x_business[a] <= asientos[a];

# RESTRICCIÓN 8 - No se puede superar la capacidad máxima de cada avión (1kg billetes estándar, 20kg leisure, 40kg business)
s.t. LimiteCapacidad{a in AVIONES}:
    x_estandar[a] * 1 + x_leisure[a] * 20 + x_business[a] * 40 <= capacidad[a];

# RESTRICCIÓN 9 - Mínimo 20 billetes leisure plus por avión
s.t. MinimoBilletesLeisure{a in AVIONES}:
    x_leisure[a] >= 20;

# RESTRICCIÓN 10 - Mínimo 10 billetes business plus por avión
s.t. MinimoBilletesBusiness{a in AVIONES}:
    x_business[a] >= 10;

# RESTRICCIÓN 11 - El número total de billetes estándar debe ser al menos el 60% del total de billetes ofertados
s.t. MinimoBilletesEstandarTotal:
    sum {a in AVIONES} x_estandar[a] >= 0.6 * sum {a in AVIONES} (x_estandar[a] + x_leisure[a] + x_business[a]);

###################
# SOLVE
###################  

solve;

for {a in AVIONES, p in PISTAS, s in SLOTS: asignado[a, p, s] == 1} {
    printf "Avión %s asignado a la pista %s en el time slot %s\n", a, p, s;
}

printf {i in AVIONES} "En el avión %s, se deben vender %d billetes Estándar, %d Leisure Plus y %d Business Plus\n", 
    i, x_estandar[i], x_leisure[i], x_business[i];

printf "Estándar: %d, Leisure: %d, Business: %d \n", sum {i in AVIONES} x_estandar[i], sum {i in AVIONES} x_leisure[i], sum {i in AVIONES} x_business[i];
printf "COSTE RETRASO: %d\n", sum {a in AVIONES, p in PISTAS, s in SLOTS} coste_retraso[a] * (s - hora_programada[a]) * asignado[a, p, s];


display beneficio_total;
end;

