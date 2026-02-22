USE Bascula;

GO

CREATE PROC ProcInsertRol  
    @NombreRol VARCHAR(50),  
    @Descripcion VARCHAR(MAX), 
    @Mensaje VARCHAR(100) OUTPUT
AS  
BEGIN  
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @NombreRol IS NULL OR @Descripcion IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

        IF LEN(TRIM(@NombreRol)) < 2 AND LEN(@NombreRol) > 50
        BEGIN
            SET @Mensaje = 'El nombre del rol debe tener al menos 2 caracteres y no exceder 50';
            RETURN;
        END

        IF LEN(TRIM(@Descripcion)) < 5 
        BEGIN
            SET @Mensaje = 'La descripcion debe tener al menos 5 caracteres';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar nombre unico 
        IF EXISTS (
            SELECT 1 FROM Rol WITH (UPDLOCK)
            WHERE NombreRol = TRIM(@NombreRol)
              AND EstadoRol = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe un rol activo con ese nombre';
            RETURN;
        END

        INSERT INTO Rol ( NombreRol, DescripRol )  
        VALUES ( TRIM(@NombreRol), TRIM(@Descripcion) );  

        -- Verificar insercion exitosa
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error al insertar el rol';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Rol registrado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al registrar rol: ' + ERROR_MESSAGE();
    END CATCH
END;