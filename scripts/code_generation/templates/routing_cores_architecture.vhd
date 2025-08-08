
architecture %%ROUTE_ARCHITECTURE_NAME%% of routing_cores is

    -------------------------------------------
    -- SIGNALs
    -------------------------------------------

%%ROUTE_SIGNAL_DEFINITION%%

begin

    DELAY_PROC : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then

%%ROUTE_SIGNAL_RESET%%

            else

%%ROUTE_SIGNAL_DELAY%%

            end if;
        end if;
    end process DELAY_PROC;

    -------------------------------------------
    -- OUTPUTs
    -------------------------------------------
%%ROUTE_SIGNAL_OUTPUT%%

end architecture;
