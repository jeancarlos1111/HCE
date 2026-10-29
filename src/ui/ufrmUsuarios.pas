unit ufrmUsuarios;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, CheckLst,
  uUsuario, uUsuarioService, uUsuarioRepository, uPermisos, uSesion;

type
  { TfrmUsuarios }
  TfrmUsuarios = class(TForm)
    pnlCabecera: TPanel;
    lblLogoIcono: TLabel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    btnCerrarTop: TButton;
    pnlFondo: TPanel;
    pnlLateral: TPanel;
    lblTituloLista: TLabel;
    edtBuscar: TEdit;
    gridUsuarios: TStringGrid;
    pnlEdicion: TPanel;
    pnlCardDatos: TPanel;
    lblEtiquetaDatos: TLabel;
    lblLogin: TLabel;
    edtLogin: TEdit;
    lblCedula: TLabel;
    edtCedula: TEdit;
    chkActivo: TCheckBox;
    lblNombres: TLabel;
    edtNombres: TEdit;
    lblApellidos: TLabel;
    edtApellidos: TEdit;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblTelefono: TLabel;
    edtTelefono: TEdit;
    pnlCardRoles: TPanel;
    lblEtiquetaRoles: TLabel;
    lblNotaRoles: TLabel;
    clbRoles: TCheckListBox;
    pnlCardProf: TPanel;
    lblEtiquetaProf: TLabel;
    lblTipoProf: TLabel;
    cbTipoProf: TComboBox;
    lblMpps: TLabel;
    edtMpps: TEdit;
    lblColegio: TLabel;
    edtColegio: TEdit;
    lblNroColegio: TLabel;
    edtNroColegio: TEdit;
    lblEspecialidades: TLabel;
    edtEspecialidades: TEdit;
    pnlCardBotones: TPanel;
    btnNuevo: TButton;
    btnGuardar: TButton;
    btnInactivar: TButton;
    btnResetClave: TButton;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtBuscarChange(Sender: TObject);
    procedure gridUsuariosSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnInactivarClick(Sender: TObject);
    procedure btnResetClaveClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure clbRolesItemClick(Sender: TObject; Index: integer);
  private
    FUsuarioService: TUsuarioService;
    FUsuarioRepo: IUsuarioRepository;
    FSesionActual: TSesion;
    FUsuarioIdActual: Int64;
    procedure LimpiarFormulario;
    procedure ActualizarVisibilidadProfesional;
    procedure CargarGridUsuarios(const AFiltro: string = '');
    procedure CargarUsuarioEnFormulario(AId: Int64);
  public
    property UsuarioService: TUsuarioService read FUsuarioService write FUsuarioService;
    property UsuarioRepo: IUsuarioRepository read FUsuarioRepo write FUsuarioRepo;
    property SesionActual: TSesion read FSesionActual write FSesionActual;
  end;

var
  frmUsuarios: TfrmUsuarios;

implementation

{$R *.lfm}

procedure TfrmUsuarios.FormCreate(Sender: TObject);
begin
  FUsuarioIdActual := 0;
  clbRoles.Items.Clear;
  clbRoles.Items.Add(ROL_ADMIN);
  clbRoles.Items.Add(ROL_MEDICO);
  clbRoles.Items.Add(ROL_ENFERMERIA);
  clbRoles.Items.Add(ROL_RECEPCION);
  clbRoles.Items.Add(ROL_ESTADISTICA);
  clbRoles.Items.Add(ROL_AUDITOR);
  clbRoles.Items.Add(ROL_DIRECCION_MEDICA);

  cbTipoProf.Items.Clear;
  cbTipoProf.Items.Add('MEDICO');
  cbTipoProf.Items.Add('ENFERMERIA');
  cbTipoProf.Items.Add('BIOANALISTA');
  cbTipoProf.ItemIndex := 0;

  LimpiarFormulario;
end;

procedure TfrmUsuarios.FormShow(Sender: TObject);
begin
  CargarGridUsuarios('');
end;

procedure TfrmUsuarios.ActualizarVisibilidadProfesional;
var
  EsAsistencial: Boolean;
begin
  EsAsistencial := clbRoles.Checked[clbRoles.Items.IndexOf(ROL_MEDICO)] or
                   clbRoles.Checked[clbRoles.Items.IndexOf(ROL_ENFERMERIA)];
  pnlCardProf.Enabled := EsAsistencial;
  cbTipoProf.Enabled := EsAsistencial;
  edtMpps.Enabled := EsAsistencial;
  edtColegio.Enabled := EsAsistencial;
  edtNroColegio.Enabled := EsAsistencial;
  edtEspecialidades.Enabled := EsAsistencial;
end;

procedure TfrmUsuarios.clbRolesItemClick(Sender: TObject; Index: integer);
begin
  ActualizarVisibilidadProfesional;
end;

procedure TfrmUsuarios.CargarGridUsuarios(const AFiltro: string);
var
  Lista: TFPList;
  i: Integer;
  U: TUsuario;
  EstadoStr: string;
begin
  if FUsuarioRepo = nil then Exit;

  gridUsuarios.RowCount := 1;
  Lista := FUsuarioRepo.Listar(AFiltro);
  try
    gridUsuarios.RowCount := Lista.Count + 1;
    for i := 0 to Lista.Count - 1 do
    begin
      U := TUsuario(Lista[i]);
      if U.Estado = euActivo then
        EstadoStr := 'Activo'
      else if U.Estado = euInactivo then
        EstadoStr := 'Inactivo'
      else
        EstadoStr := 'Bloqueado';

      gridUsuarios.Cells[0, i + 1] := IntToStr(U.Id);
      gridUsuarios.Cells[1, i + 1] := U.Login;
      gridUsuarios.Cells[2, i + 1] := U.Cedula;
      gridUsuarios.Cells[3, i + 1] := U.Nombres + ' ' + U.Apellidos;
      gridUsuarios.Cells[4, i + 1] := EstadoStr;
    end;
  finally
    for i := 0 to Lista.Count - 1 do
      TObject(Lista[i]).Free;
    Lista.Free;
  end;
end;

procedure TfrmUsuarios.edtBuscarChange(Sender: TObject);
begin
  CargarGridUsuarios(edtBuscar.Text);
end;

procedure TfrmUsuarios.gridUsuariosSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  IdStr: string;
  Id: Int64;
begin
  CanSelect := True;
  if aRow >= 1 then
  begin
    IdStr := gridUsuarios.Cells[0, aRow];
    if TryStrToInt64(IdStr, Id) and (Id > 0) then
      CargarUsuarioEnFormulario(Id);
  end;
end;

procedure TfrmUsuarios.CargarUsuarioEnFormulario(AId: Int64);
var
  Usuario: TUsuario;
  i, RolIdx: Integer;
begin
  if FUsuarioRepo = nil then Exit;

  Usuario := FUsuarioRepo.ObtenerPorId(AId);
  if Usuario = nil then Exit;
  try
    FUsuarioIdActual := Usuario.Id;
    edtLogin.Text := Usuario.Login;
    edtLogin.Enabled := False; // No modificable una vez creado
    edtCedula.Text := Usuario.Cedula;
    edtCedula.Enabled := False; // No modificable una vez creado
    edtNombres.Text := Usuario.Nombres;
    edtApellidos.Text := Usuario.Apellidos;
    edtEmail.Text := Usuario.Email;
    edtTelefono.Text := Usuario.Telefono;
    chkActivo.Checked := (Usuario.Estado = euActivo);

    for i := 0 to clbRoles.Items.Count - 1 do
      clbRoles.Checked[i] := False;

    for i := 0 to Usuario.Roles.Count - 1 do
    begin
      RolIdx := clbRoles.Items.IndexOf(Usuario.Roles[i]);
      if RolIdx >= 0 then
        clbRoles.Checked[RolIdx] := True;
    end;

    if Usuario.EsProfesional then
    begin
      cbTipoProf.Text := Usuario.Profesional.Tipo;
      edtMpps.Text := Usuario.Profesional.Mpps;
      edtColegio.Text := Usuario.Profesional.Colegio;
      edtNroColegio.Text := Usuario.Profesional.NroColegio;
      edtEspecialidades.Text := Usuario.Profesional.Especialidades;
    end
    else
    begin
      cbTipoProf.ItemIndex := 0;
      edtMpps.Clear;
      edtColegio.Clear;
      edtNroColegio.Clear;
      edtEspecialidades.Clear;
    end;

    ActualizarVisibilidadProfesional;
  finally
    Usuario.Free;
  end;
end;

procedure TfrmUsuarios.LimpiarFormulario;
var
  i: Integer;
begin
  FUsuarioIdActual := 0;
  edtLogin.Clear;
  edtLogin.Enabled := True;
  edtCedula.Clear;
  edtCedula.Enabled := True;
  edtNombres.Clear;
  edtApellidos.Clear;
  edtEmail.Clear;
  edtTelefono.Clear;
  chkActivo.Checked := True;

  for i := 0 to clbRoles.Items.Count - 1 do
    clbRoles.Checked[i] := False;

  cbTipoProf.ItemIndex := 0;
  edtMpps.Clear;
  edtColegio.Clear;
  edtNroColegio.Clear;
  edtEspecialidades.Clear;
  ActualizarVisibilidadProfesional;
end;

procedure TfrmUsuarios.btnNuevoClick(Sender: TObject);
begin
  LimpiarFormulario;
  edtLogin.SetFocus;
end;

procedure TfrmUsuarios.btnGuardarClick(Sender: TObject);
var
  Usuario: TUsuario;
  i: Integer;
  Prof: TProfesional;
  ClaveTemporal: string;
begin
  if Trim(edtLogin.Text) = '' then
  begin
    ShowMessage('El usuario es obligatorio');
    edtLogin.SetFocus;
    Exit;
  end;
  if Trim(edtCedula.Text) = '' then
  begin
    ShowMessage('La cedula es obligatoria (ej. V-12345678)');
    edtCedula.SetFocus;
    Exit;
  end;

  Usuario := TUsuario.Create;
  try
    Usuario.Id := FUsuarioIdActual;
    Usuario.Login := Trim(edtLogin.Text);
    Usuario.Cedula := Trim(edtCedula.Text);
    Usuario.Nombres := Trim(edtNombres.Text);
    Usuario.Apellidos := Trim(edtApellidos.Text);
    Usuario.Email := Trim(edtEmail.Text);
    Usuario.Telefono := Trim(edtTelefono.Text);
    if chkActivo.Checked then
      Usuario.Estado := euActivo
    else
      Usuario.Estado := euInactivo;

    for i := 0 to clbRoles.Items.Count - 1 do
    begin
      if clbRoles.Checked[i] then
        Usuario.Roles.Add(clbRoles.Items[i]);
    end;

    if pnlCardProf.Enabled then
    begin
      Usuario.EsProfesional := True;
      Prof.Tipo := cbTipoProf.Text;
      Prof.Mpps := Trim(edtMpps.Text);
      Prof.Colegio := Trim(edtColegio.Text);
      Prof.NroColegio := Trim(edtNroColegio.Text);
      Prof.Especialidades := Trim(edtEspecialidades.Text);
      Usuario.Profesional := Prof;
    end
    else
      Usuario.EsProfesional := False;

    if FUsuarioIdActual = 0 then
    begin
      ClaveTemporal := 'Temporal2026!';
      FUsuarioService.CrearUsuario(Usuario, ClaveTemporal);
      ShowMessageFmt('Usuario "%s" creado con exito.' + sLineBreak +
                     'Contrasena temporal asignada: %s', [Usuario.Login, ClaveTemporal]);
    end
    else
    begin
      FUsuarioService.ActualizarUsuario(Usuario);
      ShowMessage('Usuario actualizado con exito.');
    end;

    LimpiarFormulario;
    CargarGridUsuarios(edtBuscar.Text);
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message);
  end;
  Usuario.Free;
end;

procedure TfrmUsuarios.btnInactivarClick(Sender: TObject);
var
  Motivo: string;
begin
  if FUsuarioIdActual = 0 then
  begin
    ShowMessage('Seleccione un usuario de la lista para inactivar');
    Exit;
  end;

  Motivo := InputBox('Inactivar Usuario', 'Ingrese motivo de la inactivacion:', 'Desincorporacion');
  if Trim(Motivo) = '' then Exit;

  try
    FUsuarioService.InactivarUsuario(FUsuarioIdActual, Motivo);
    ShowMessage('Usuario inactivado con exito.');
    LimpiarFormulario;
    CargarGridUsuarios(edtBuscar.Text);
  except
    on E: Exception do
      ShowMessage('Error al inactivar: ' + E.Message);
  end;
end;

procedure TfrmUsuarios.btnResetClaveClick(Sender: TObject);
var
  NuevaClaveTemp: string;
begin
  if FUsuarioIdActual = 0 then
  begin
    ShowMessage('Seleccione un usuario de la lista para resetear su contrasena');
    Exit;
  end;

  NuevaClaveTemp := 'Reset2026!';
  try
    FUsuarioService.ResetearClave(FUsuarioIdActual, NuevaClaveTemp);
    ShowMessageFmt('Contrasena reseteada con exito.' + sLineBreak +
                   'Nueva clave temporal: %s', [NuevaClaveTemp]);
  except
    on E: Exception do
      ShowMessage('Error al resetear contrasena: ' + E.Message);
  end;
end;

procedure TfrmUsuarios.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
