!> \file
!> $Id: CylinderInflationExample.f90  $
!> \author Jack Lee
!> \brief This is an example program to solve a finite elasticity equation using openCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is openCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s): Jack Lee
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>



!> Main program
PROGRAM CYLINDERINFLATIONEXAMPLE

  USE BASE_ROUTINES   
  USE BASIS_ROUTINES   
  USE BOUNDARY_CONDITIONS_ROUTINES   
  USE CMISS   
  USE CMISS_MPI    
  USE CMISS_PETSC   
  USE COMP_ENVIRONMENT   
  USE CONSTANTS    
  USE CONTROL_LOOP_ROUTINES   
  USE COORDINATE_ROUTINES   
  USE CYLINDERINFLATIONANALYTIC
  USE DISTRIBUTED_MATRIX_VECTOR    
  USE DOMAIN_MAPPINGS   
  USE EQUATIONS_ROUTINES   
  USE EQUATIONS_SET_CONSTANTS   
  USE EQUATIONS_SET_ROUTINES   
  USE FIELD_ROUTINES   
  USE FIELD_IO_ROUTINES 
  USE GENERATED_MESH_ROUTINES   
  USE INPUT_OUTPUT   
  USE ISO_VARYING_STRING   
  USE KINDS   
  USE LISTS   
  USE MESH_ROUTINES   
  USE MPI   
  USE NODE_ROUTINES     
  USE PROBLEM_CONSTANTS    
  USE PROBLEM_ROUTINES   
  USE REGION_ROUTINES   
  USE SOLID_MECHANICS_IO_CYLINDER_GEOMETRY
  USE SOLID_MECHANICS_IO_ROUTINES
  USE SOLVER_ROUTINES   
  USE TIMER   
  USE TYPES

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Program variables

  INTEGER(INTG) :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS
  INTEGER(INTG) :: NUMBER_COMPUTATIONAL_NODES,NUMBER_OF_DOMAINS,MY_COMPUTATIONAL_NODE_NUMBER,MPI_IERROR
  INTEGER(INTG) :: EQUATIONS_SET_INDEX  
  INTEGER(INTG) :: first_global_dof,first_local_dof,first_local_rank,last_global_dof,last_local_dof,last_local_rank,rank_idx

  TYPE(BASIS_TYPE), POINTER :: BASIS
  TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS
  TYPE(COORDINATE_SYSTEM_TYPE), POINTER :: COORDINATE_SYSTEM
  TYPE(MESH_TYPE), POINTER :: MESH
  TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
  TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
  TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
  TYPE(FIELD_TYPE), POINTER :: GEOMETRIC_FIELD,FIBRE_FIELD,MATERIAL_FIELD,DEPENDENT_FIELD
  TYPE(PROBLEM_TYPE), POINTER :: PROBLEM
  TYPE(REGION_TYPE), POINTER :: REGION,WORLD_REGION
  TYPE(SOLVER_TYPE), POINTER :: SOLVER,LINEAR_SOLVER
  TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
  TYPE(NODES_TYPE), POINTER :: NODES
  TYPE(MESH_ELEMENTS_TYPE), POINTER :: ELEMENTS

  LOGICAL :: EXPORT_FIELD,IMPORT_FIELD
  TYPE(VARYING_STRING) :: FILE,METHOD

  REAL(SP) :: START_USER_TIME(1),STOP_USER_TIME(1),START_SYSTEM_TIME(1),STOP_SYSTEM_TIME(1)

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS variables
  INTEGER(INTG) :: ERR
  TYPE(VARYING_STRING) :: ERROR
  INTEGER(INTG) :: DIAG_LEVEL_LIST(5)
  CHARACTER(LEN=MAXSTRLEN) :: DIAG_ROUTINE_LIST(1),TIMING_ROUTINE_LIST(1)

  !local variables
  INTEGER(INTG) :: coordinate_system_user_number,number_of_spatial_coordinates
  INTEGER(INTG) :: region_user_number
  INTEGER(INTG) :: basis_user_number,number_of_xi_coordinates  
  INTEGER(INTG) :: total_number_of_nodes,node_idx,global_node_number  
  INTEGER(INTG) :: mesh_user_number,number_of_mesh_dimensions,number_of_mesh_components
  INTEGER(INTG) :: total_number_of_elements,mesh_component_number
  INTEGER(INTG) :: decomposition_user_number  
  INTEGER(INTG) :: field_geomtery_user_number,field_geometry_number_of_varaiables,field_geometry_number_of_components  
  INTEGER(INTG) :: field_fibre_user_number,field_fibre_number_of_varaiables,field_fibre_number_of_components 
  INTEGER(INTG) :: field_material_user_number,field_material_number_of_varaiables,field_material_number_of_components 
  INTEGER(INTG) :: field_dependent_user_number,field_dependent_number_of_varaiables,field_dependent_number_of_components 
  INTEGER(INTG) :: equation_set_user_number
  INTEGER(INTG) :: problem_user_number     
  INTEGER(INTG) :: dof_idx,number_of_global_dependent_dofs,number_of_global_geometric_dofs  
  REAL(DP), POINTER :: FIELD_DATA(:)
integer(intg) :: i,j,k
  ! io variables
  TYPE(VARYING_STRING) :: FILENAME
  TYPE(SOLID_MECHANICS_IO_CYLINDER) :: IMPORT_CYLINDER
  TYPE(SOLID_MECHANICS_IO_MESH_CONTAINER) :: IMPORT_MESH
  TYPE(SOLID_MECHANICS_IO_BOUNDARY_CONDITION),ALLOCATABLE :: IMPORT_BC(:)
  REAL(DP) :: MU1,MU2     ! analytic solutions (radius ratios)
  REAL(DP) :: IMPORT_PROB(3) ! P_inner, P_outer and lambda
  CHARACTER*10 :: WORD
  REAL(DP) :: ARGS(9)     ! to hold the commandline arguments

! TYPE(FIELD_INTERPOLATION_PARAMETERS_TYPE), POINTER :: DEPENDENT_INTERPOLATION_PARAMETERS
TYPE(DISTRIBUTED_VECTOR_TYPE),POINTER :: dis_vec
INTEGER(INTG) :: FILEUNIT

#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="Cylinder Inflation Example Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  !Intialise cmiss
  NULLIFY(WORLD_REGION)
  CALL CMISS_INITIALISE(WORLD_REGION,ERR,ERROR,*999)

  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"*** PROGRAM STARTING ********************",ERR,ERROR,*999)

  !Set all diganostic levels on for testing
  DIAG_LEVEL_LIST(1)=1
  DIAG_LEVEL_LIST(2)=2
  DIAG_LEVEL_LIST(3)=3
  DIAG_LEVEL_LIST(4)=4
  DIAG_LEVEL_LIST(5)=5

! set diagnostics on
! CALL DIAGNOSTICS_SET_ON(ALL_DIAG_TYPE,DIAG_LEVEL_LIST,"",(/"",""/),Err,ERROR,*999)
 CALL DIAGNOSTICS_SET_ON(FROM_DIAG_TYPE,DIAG_LEVEL_LIST,'Diagnostics',(/'FIELD_MAPPINGS_CALCULATE'/),ERR,ERROR,*999)

  TIMING_ROUTINE_LIST(1)="PROBLEM_FINITE_ELEMENT_CALCULATE"

  !Calculate the start times
  CALL CPU_TIMER(USER_CPU,START_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,START_SYSTEM_TIME,ERR,ERROR,*999)

  !Get the number of computational nodes
  NUMBER_COMPUTATIONAL_NODES=COMPUTATIONAL_NODES_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999
  !Get my computational node number
  MY_COMPUTATIONAL_NODE_NUMBER=COMPUTATIONAL_NODE_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999

!   FILENAME = './input/cylinder.mesh'
!   call SOLID_MECHANICS_IO_READ_MESH(FILENAME,IMPORT_MESH,ERR,ERROR,*999)              ! to read mesh
!   call SOLID_MECHANICS_IO_WRITE_MESH(6,IMPORT_MESH,*999)                              ! print to screen
!   FILENAME='./input/CylinderInflation.bc'
!   call SOLID_MECHANICS_IO_READ_BC(FILENAME,IMPORT_BC,ERR,ERROR,*999)

  !IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
  !  ! favour on-the-fly over file I/O, since it can be very large
  !  IF(COMMAND_ARGUMENT_COUNT()==9) THEN
  !    DO I=1,9
  !      CALL GET_COMMAND_ARGUMENT(I,WORD)
 !       READ(WORD,*) ARGS(I)
 !     ENDDO
!    ELSE ! read parameters from user
!      CALL SOLID_MECHANICS_IO_CREATE_CYLINDER(IMPORT_CYLINDER,IMPORT_MESH,ERR,ERROR,*999)
 !     CALL SOLID_MECHANICS_IO_CREATE_BC(IMPORT_CYLINDER,IMPORT_BC,ERR,ERROR,*999,IMPORT_PROB)
!    ENDIF
!  ENDIF

  ARGS(1)=0.5_DP
  ARGS(2)=1.0_DP
  ARGS(3)=0.1_DP
  ARGS(4)=1.0_DP
  ARGS(5)=16.0_DP
  ARGS(6)=1.0_DP
  ARGS(7)=1.0_DP
  ARGS(8)=0.0_DP
  ARGS(9)=1.1_DP
  
  ! broadcast to other nodes
  CALL MPI_BCAST(ARGS,9,MPI_DOUBLE,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)

  !IF(COMMAND_ARGUMENT_COUNT()==9) THEN
    ! generate a cylinder mesh
    CALL SOLID_MECHANICS_IO_CREATE_CYLINDER(IMPORT_CYLINDER,IMPORT_MESH,ERR,ERROR,*999,ARGS)
    ! import boundary conditions
    CALL SOLID_MECHANICS_IO_CREATE_BC(IMPORT_CYLINDER,IMPORT_BC,ERR,ERROR,*999,IMPORT_PROB,ARGS)
  !ENDIF

  IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
    ! Calculate analytic examples here
    ! bugger, R1 and R2 are swapped over in Marty's writeup
    CALL CYLINDER_INFLATION_SOLVE(IMPORT_CYLINDER%R2,IMPORT_CYLINDER%R1,2.0_DP,6.0_DP, &
      & IMPORT_PROB(1),IMPORT_PROB(2),IMPORT_PROB(3),MU1,MU2)
    ! let's convert it to radius, since I'm lazy
    MU1=MU1*IMPORT_CYLINDER%R2
    MU2=MU2*IMPORT_CYLINDER%R1
  ENDIF

  ! let's take this from the number of nodes started
  NUMBER_OF_DOMAINS = NUMBER_COMPUTATIONAL_NODES
  write(*,*) "NUMBER_OF_DOMAINS=",NUMBER_OF_DOMAINS

  !Broadcast the number of partitions to the other computational nodes
  CALL MPI_BCAST(NUMBER_OF_DOMAINS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_ERROR_CHECK("MPI_BCAST",MPI_IERROR,ERR,ERROR,*999)

  !Create a CS - default is 3D rectangular cartesian CS with 0,0,0 as origin
  coordinate_system_user_number=1
  number_of_spatial_coordinates=3
  NULLIFY(COORDINATE_SYSTEM)
  CALL COORDINATE_SYSTEM_CREATE_START(coordinate_system_user_number,COORDINATE_SYSTEM,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_TYPE_SET(COORDINATE_SYSTEM,COORDINATE_RECTANGULAR_CARTESIAN_TYPE,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,number_of_spatial_coordinates,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_ORIGIN_SET(COORDINATE_SYSTEM,(/0.0_DP,0.0_DP,0.0_DP/),ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_CREATE_FINISH(COORDINATE_SYSTEM,ERR,ERROR,*999)

  !Create a region and assign the CS to the region
  region_user_number=1
  NULLIFY(REGION)
  CALL REGION_CREATE_START(region_user_number,WORLD_REGION,REGION,ERR,ERROR,*999)
  CALL REGION_COORDINATE_SYSTEM_SET(REGION,COORDINATE_SYSTEM,ERR,ERROR,*999)
  CALL REGION_CREATE_FINISH(REGION,ERR,ERROR,*999)

  !Define basis function - tri-linear Lagrange  
  basis_user_number=1 
  number_of_xi_coordinates=3
  NULLIFY(BASIS)
  CALL BASIS_CREATE_START(basis_user_number,BASIS,ERR,ERROR,*999) 
  CALL BASIS_TYPE_SET(BASIS,BASIS_LAGRANGE_HERMITE_TP_TYPE,ERR,ERROR,*999)
  CALL BASIS_NUMBER_OF_XI_SET(BASIS,number_of_xi_coordinates,ERR,ERROR,*999)
  CALL BASIS_INTERPOLATION_XI_SET(BASIS,(/BASIS_LINEAR_LAGRANGE_INTERPOLATION, &
    & BASIS_LINEAR_LAGRANGE_INTERPOLATION,BASIS_LINEAR_LAGRANGE_INTERPOLATION/),ERR,ERROR,*999)
  CALL BASIS_QUADRATURE_NUMBER_OF_GAUSS_XI_SET(BASIS,(/3,3,3/),ERR,ERROR,*999)  
  CALL BASIS_CREATE_FINISH(BASIS,ERR,ERROR,*999)

  !Create a mesh
  mesh_user_number=1
  number_of_mesh_dimensions=3
  number_of_mesh_components=1
  total_number_of_elements=IMPORT_MESH%NE
  NULLIFY(MESH)
  CALL MESH_CREATE_START(mesh_user_number,REGION,number_of_mesh_dimensions,MESH,ERR,ERROR,*999)    

    CALL MESH_NUMBER_OF_COMPONENTS_SET(MESH,number_of_mesh_components,ERR,ERROR,*999) 
    CALL MESH_NUMBER_OF_ELEMENTS_SET(MESH,total_number_of_elements,ERR,ERROR,*999)  

    !define nodes for the mesh
    total_number_of_nodes=IMPORT_MESH%NN
    NULLIFY(NODES)
    CALL NODES_CREATE_START(REGION,total_number_of_nodes,NODES,ERR,ERROR,*999)
    CALL NODES_CREATE_FINISH(NODES,ERR,ERROR,*999)

    mesh_component_number=1
    NULLIFY(ELEMENTS)
    CALL MESH_TOPOLOGY_ELEMENTS_CREATE_START(MESH,mesh_component_number,BASIS,ELEMENTS,ERR,ERROR,*999)
      CALL SOLID_MECHANICS_IO_ASSIGN_ELEMENTS(IMPORT_MESH,ELEMENTS,ERR,ERROR,*999)
!     CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(MESH,mesh_component_number,ERR,ERROR,*999)
    CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(ELEMENTS,ERR,ERROR,*999)

  CALL MESH_CREATE_FINISH(MESH,ERR,ERROR,*999) 

  !Create a decomposition
  decomposition_user_number=1
  NULLIFY(DECOMPOSITION)
  CALL DECOMPOSITION_CREATE_START(decomposition_user_number,MESH,DECOMPOSITION,ERR,ERROR,*999)
    CALL DECOMPOSITION_TYPE_SET(DECOMPOSITION,DECOMPOSITION_CALCULATED_TYPE,ERR,ERROR,*999)
    CALL DECOMPOSITION_NUMBER_OF_DOMAINS_SET(DECOMPOSITION,number_of_domains,ERR,ERROR,*999)
  CALL DECOMPOSITION_CREATE_FINISH(DECOMPOSITION,ERR,ERROR,*999)

  !Create a field to put the geometry (defualt is geometry)
  field_geomtery_user_number=1  
  field_geometry_number_of_varaiables=1
  field_geometry_number_of_components=3
  NULLIFY(GEOMETRIC_FIELD)
  CALL FIELD_CREATE_START(field_geomtery_user_number,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
    CALL FIELD_MESH_DECOMPOSITION_SET(GEOMETRIC_FIELD,DECOMPOSITION,ERR,ERROR,*999)
    CALL FIELD_TYPE_SET(GEOMETRIC_FIELD,FIELD_GEOMETRIC_TYPE,ERR,ERROR,*999)  
    CALL FIELD_NUMBER_OF_VARIABLES_SET(GEOMETRIC_FIELD,field_geometry_number_of_varaiables,ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_COMPONENTS_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,field_geometry_number_of_components,ERR,ERROR,*999)  
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,1,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,2,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,3,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_LABEL_SET_AND_LOCK(GEOMETRIC_FIELD,'Geometric Field',ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(GEOMETRIC_FIELD,ERR,ERROR,*999)

  ! assign imported nodes to mesh: GEOMETRIC_FIELD is distributed, so this has to be also
  CALL SOLID_MECHANICS_IO_ASSIGN_NODES(IMPORT_MESH,GEOMETRIC_FIELD,ERR,ERROR,*999)

  IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
    ! export to cmgui
    FILE="./test"
    METHOD="FORTRAN"
    CALL FIELD_IO_NODES_EXPORT(REGION%FIELDS, FILE, METHOD, ERR,ERROR,*999)  
    CALL FIELD_IO_ELEMENTS_EXPORT(REGION%FIELDS, FILE, METHOD, ERR,ERROR,*999)
  ENDIF
  
  !Create a fibre field and attach it to the geometric field  
  field_fibre_user_number=2  
  field_fibre_number_of_varaiables=1
  field_fibre_number_of_components=3
  NULLIFY(FIBRE_FIELD)
  CALL FIELD_CREATE_START(field_fibre_user_number,REGION,FIBRE_FIELD,ERR,ERROR,*999)
    CALL FIELD_TYPE_SET(FIBRE_FIELD,FIELD_FIBRE_TYPE,ERR,ERROR,*999)
    CALL FIELD_MESH_DECOMPOSITION_SET(FIBRE_FIELD,DECOMPOSITION,ERR,ERROR,*999)        
    CALL FIELD_GEOMETRIC_FIELD_SET(FIBRE_FIELD,GEOMETRIC_FIELD,ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_VARIABLES_SET(FIBRE_FIELD,field_fibre_number_of_varaiables,ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_COMPONENTS_SET(FIBRE_FIELD,FIELD_U_VARIABLE_TYPE,field_fibre_number_of_components,ERR,ERROR,*999)  
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(FIBRE_FIELD,FIELD_U_VARIABLE_TYPE,1,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(FIBRE_FIELD,FIELD_U_VARIABLE_TYPE,2,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(FIBRE_FIELD,FIELD_U_VARIABLE_TYPE,3,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_LABEL_SET_AND_LOCK(FIBRE_FIELD,'Fibre Field',ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(FIBRE_FIELD,ERR,ERROR,*999)

  !Create a material field and attach it to the geometric field  
  field_material_user_number=3  
  field_material_number_of_varaiables=1
  field_material_number_of_components=2
  NULLIFY(MATERIAL_FIELD)
  CALL FIELD_CREATE_START(field_material_user_number,REGION,MATERIAL_FIELD,ERR,ERROR,*999)
    CALL FIELD_TYPE_SET(MATERIAL_FIELD,FIELD_MATERIAL_TYPE,ERR,ERROR,*999)
    CALL FIELD_MESH_DECOMPOSITION_SET(MATERIAL_FIELD,DECOMPOSITION,ERR,ERROR,*999)        
    CALL FIELD_GEOMETRIC_FIELD_SET(MATERIAL_FIELD,GEOMETRIC_FIELD,ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_VARIABLES_SET(MATERIAL_FIELD,field_material_number_of_varaiables,ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_COMPONENTS_SET(MATERIAL_FIELD,FIELD_U_VARIABLE_TYPE,field_material_number_of_components,ERR,ERROR,*999)  
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(MATERIAL_FIELD,FIELD_U_VARIABLE_TYPE,1,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(MATERIAL_FIELD,FIELD_U_VARIABLE_TYPE,2,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_LABEL_SET_AND_LOCK(MATERIAL_FIELD,'Material Field',ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(MATERIAL_FIELD,ERR,ERROR,*999)

  !Set Mooney-Rivlin constants c10 and c01 to 2.0 and 3.0 respectively.
  CALL FIELD_COMPONENT_VALUES_INITIALISE(MATERIAL_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,1,2.0_DP,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_VALUES_INITIALISE(MATERIAL_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,2,6.0_DP,ERR,ERROR,*999)    ! used to be 3.0_DP

  !Create a dependent field with two variables and four components
  field_dependent_user_number=4  
  field_dependent_number_of_varaiables=2
  field_dependent_number_of_components=4
  NULLIFY(DEPENDENT_FIELD)
  CALL FIELD_CREATE_START(field_dependent_user_number,REGION,DEPENDENT_FIELD,ERR,ERROR,*999)
    CALL FIELD_TYPE_SET(DEPENDENT_FIELD,FIELD_GENERAL_TYPE,ERR,ERROR,*999)  
    CALL FIELD_MESH_DECOMPOSITION_SET(DEPENDENT_FIELD,DECOMPOSITION,ERR,ERROR,*999)
    CALL FIELD_GEOMETRIC_FIELD_SET(DEPENDENT_FIELD,GEOMETRIC_FIELD,ERR,ERROR,*999) 
    CALL FIELD_DEPENDENT_TYPE_SET(DEPENDENT_FIELD,FIELD_DEPENDENT_TYPE,ERR,ERROR,*999) 
    CALL FIELD_NUMBER_OF_VARIABLES_SET(DEPENDENT_FIELD,field_dependent_number_of_varaiables,ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_COMPONENTS_SET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,field_dependent_number_of_components, &
      & ERR,ERROR,*999)
    CALL FIELD_NUMBER_OF_COMPONENTS_SET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,field_dependent_number_of_components, &
      & ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,1,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,2,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,3,mesh_component_number,ERR,ERROR,*999)  
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,4,mesh_component_number,ERR,ERROR,*999)  
!     CALL FIELD_COMPONENT_INTERPOLATION_SET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,4,FIELD_ELEMENT_BASED_INTERPOLATION,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,1,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,2,mesh_component_number,ERR,ERROR,*999)
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,3,mesh_component_number,ERR,ERROR,*999)  
    CALL FIELD_COMPONENT_MESH_COMPONENT_SET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,4,mesh_component_number,ERR,ERROR,*999)  
!     CALL FIELD_COMPONENT_INTERPOLATION_SET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,4,FIELD_ELEMENT_BASED_INTERPOLATION, &
!       & ERR,ERROR,*999)
    CALL FIELD_LABEL_SET_AND_LOCK(DEPENDENT_FIELD,'Dependent Field',ERR,ERROR,*999)
  CALL FIELD_CREATE_FINISH(DEPENDENT_FIELD,ERR,ERROR,*999)

number_of_global_dependent_dofs=DEPENDENT_FIELD%VARIABLES(1)%NUMBER_OF_GLOBAL_DOFS
write(*,*)
write(*,*) "number_of_global_dependent_dofs=",number_of_global_dependent_dofs

  !Create the equations_set
  equation_set_user_number=1
  CALL EQUATIONS_SET_CREATE_START(equation_set_user_number,REGION,FIBRE_FIELD,EQUATIONS_SET,ERR,ERROR,*999)
  CALL EQUATIONS_SET_SPECIFICATION_SET(EQUATIONS_SET,EQUATIONS_SET_ELASTICITY_CLASS, &
    & EQUATIONS_SET_FINITE_ELASTICITY_TYPE,EQUATIONS_SET_NO_SUBTYPE,ERR,ERROR,*999)
  CALL EQUATIONS_SET_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

  CALL EQUATIONS_SET_DEPENDENT_CREATE_START(equations_set,field_dependent_user_number,DEPENDENT_FIELD,ERR,ERROR,*999) 
  CALL EQUATIONS_SET_DEPENDENT_CREATE_FINISH(equations_set,ERR,ERROR,*999)

  CALL EQUATIONS_SET_MATERIALS_CREATE_START(EQUATIONS_SET,field_material_user_number,MATERIAL_FIELD,ERR,ERROR,*999)  
  CALL EQUATIONS_SET_MATERIALS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

  !Create the equations set equations
  NULLIFY(EQUATIONS)
  CALL EQUATIONS_SET_EQUATIONS_CREATE_START(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
  CALL EQUATIONS_SPARSITY_TYPE_SET(EQUATIONS,EQUATIONS_SPARSE_MATRICES,ERR,ERROR,*999)
  CALL EQUATIONS_OUTPUT_TYPE_SET(EQUATIONS,EQUATIONS_NO_OUTPUT,ERR,ERROR,*999)
  CALL EQUATIONS_SET_EQUATIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)   

  !Initialise dependent field from undeformed geometry and displacement bcs and set hydrostatic pressure
  CALL FIELD_PARAMETERS_TO_FIELD_PARAMETERS_COMPONENT_COPY(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
    & 1,DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,1,ERR,ERROR,*999)
  CALL FIELD_PARAMETERS_TO_FIELD_PARAMETERS_COMPONENT_COPY(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
    & 2,DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,2,ERR,ERROR,*999)
  CALL FIELD_PARAMETERS_TO_FIELD_PARAMETERS_COMPONENT_COPY(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
    & 3,DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,3,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_VALUES_INITIALISE(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,4,0.0_DP,ERR,ERROR,*999) ! initial hydrostatic pressure used to be -8.0_DP? >>it doesn't change anything

  !Prescribe boundary conditions (absolute nodal parameters)
  NULLIFY(BOUNDARY_CONDITIONS)
  CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_CREATE_START(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
  ! use the imported boundary conditions
  call SOLID_MECHANICS_IO_ASSIGN_BC(IMPORT_BC,BOUNDARY_CONDITIONS,IMPORT_MESH,ERR,ERROR,*999)
  CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

  ! imported mesh and bc are no longer needed - clean up
  call SOLID_MECHANICS_IO_CLEAR_MESH(IMPORT_MESH,ERR,ERROR,*999)
  call SOLID_MECHANICS_IO_CLEAR_BC(IMPORT_BC,ERR,ERROR,*999)

  !Define the problem
  NULLIFY(PROBLEM)
  problem_user_number=1
  CALL PROBLEM_CREATE_START(problem_user_number,PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_SPECIFICATION_SET(PROBLEM,PROBLEM_ELASTICITY_CLASS,PROBLEM_FINITE_ELASTICITY_TYPE, &
    & PROBLEM_NO_SUBTYPE,ERR,ERROR,*999)
  CALL PROBLEM_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem control loop
  CALL PROBLEM_CONTROL_LOOP_CREATE_START(PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_CONTROL_LOOP_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem solvers
  NULLIFY(SOLVER)
  NULLIFY(LINEAR_SOLVER)
  CALL PROBLEM_SOLVERS_CREATE_START(PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
  call SOLVER_NEWTON_LINEAR_SOLVER_GET(SOLVER,LINEAR_SOLVER,ERR,ERROR,*999)
  call SOLVER_LINEAR_TYPE_SET (LINEAR_SOLVER, SOLVER_LINEAR_DIRECT_SOLVE_TYPE, ERR, ERROR,*999)
! call SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET(LINEAR_SOLVER, 1E-6_dp, ERR, ERROR,*999)
  CALL SOLVER_OUTPUT_TYPE_SET(SOLVER,SOLVER_PROGRESS_OUTPUT,ERR,ERROR,*999)
  CALL SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET(SOLVER,SOLVER_NEWTON_JACOBIAN_FD_CALCULATED,ERR,ERROR,*999)
  !CALL SOLVER_NEWTON_LINESEARCH_ALPHA_SET(SOLVER,0.1_DP,ERR,ERROR,*999)   
  !CALL SOLVER_OUTPUT_TYPE_SET(SOLVER,SOLVER_MATRIX_OUTPUT,ERR,ERROR,*999)      
  CALL PROBLEM_SOLVERS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem solver equations
  NULLIFY(SOLVER)
  NULLIFY(SOLVER_EQUATIONS)
  CALL PROBLEM_SOLVER_EQUATIONS_CREATE_START(PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
  CALL SOLVER_SOLVER_EQUATIONS_GET(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*999)
  CALL SOLVER_EQUATIONS_SPARSITY_TYPE_SET(SOLVER_EQUATIONS,SOLVER_SPARSE_MATRICES,ERR,ERROR,*999)
  CALL SOLVER_EQUATIONS_EQUATIONS_SET_ADD(SOLVER_EQUATIONS,EQUATIONS_SET,EQUATIONS_SET_INDEX,ERR,ERROR,*999)
  CALL PROBLEM_SOLVER_EQUATIONS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

! CALL DISTRIUBTED_VECTOR_LABEL_AND_WRITE(SOLVER%solver_equations%solver_matrices &
!  & %matrices(1)%ptr%solver_vector,"SOLVAR",ERR,ERROR,*999)
! STOP ! all zeros in both serial and parallel

  !Solve problem
  CALL PROBLEM_SOLVE(PROBLEM,ERR,ERROR,*999)

  !Output solution
  write(*,*) "number of global dof =",number_of_global_dependent_dofs  
!   number_of_global_dependent_dofs=DEPENDENT_FIELD%VARIABLES(1)%NUMBER_OF_GLOBAL_DOFS
  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE," deformed geometry & hydrostatic pressure (R1 and R2)",ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,FIELD_DATA,ERR,ERROR,*999) 
!   CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,number_of_global_dependent_dofs,1,1,FIELD_DATA,'(2x,e30.17)','(2x,e30.17)', &
!     & ERR,ERROR,*999)
  CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,IMPORT_CYLINDER%NER,IMPORT_CYLINDER%NER+1,1,1, & 
      & FIELD_DATA,'(2x,e30.17)','(2x,e30.17)', ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_DATA_RESTORE(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,FIELD_DATA,ERR,ERROR,*999)

! probably wrong code to display reaction forces...
!   CALL WRITE_STRING(GENERAL_OUTPUT_TYPE," nodal reaction forces",ERR,ERROR,*999)  
!   CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,FIELD_DELUDELN_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,FIELD_DATA,ERR,ERROR,*999)  
!   CALL WRITE_STRING_VECTOR(GENERAL_OUTPUT_TYPE,1,1,number_of_global_dependent_dofs,1,1,FIELD_DATA,'(2x,f10.6)','(2x,f10.6)', &
!    & ERR,ERROR,*999)
!   CALL FIELD_PARAMETER_SET_DATA_RESTORE(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,FIELD_DATA,ERR,ERROR,*999)

  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE," nodal reaction forces ",ERR,ERROR,*999)  
!   DO dof_idx=1,number_of_global_dependent_dofs
!     WRITE(6,'(2x,e30.17)') PROBLEM%CONTROL_LOOP%SOLVERS%SOLVERS(1)%PTR%SOLVER_EQUATIONS%SOLVER_MAPPING% &
!       & EQUATIONS_SETS(1)%PTR%EQUATIONS%EQUATIONS_MATRICES%NONLINEAR_MATRICES%RESIDUAL%CMISS%DATA_DP(dof_idx)
!   ENDDO

  IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
    ! analytic solution
    write(*,*) "ANALYTIC INNER RADIUS =",MU2
    write(*,*) "ANALYTIC OUTER RADIUS =",MU1
    WRITE(*,*) "INITIAL VOLUME =",PI*(IMPORT_CYLINDER%R2**2-IMPORT_CYLINDER%R1**2)
    write(*,*) "FINAL VOLUME   =",PI*(MU1**2-MU2**2)*IMPORT_PROB(3)
  ENDIF

  !Calculate and output the elapsed user and system times
  CALL CPU_TIMER(USER_CPU,STOP_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,STOP_SYSTEM_TIME,ERR,ERROR,*999)
  CALL WRITE_STRING_FMT_TWO_VALUE(GENERAL_OUTPUT_TYPE," USER TIME = ",STOP_USER_TIME(1)-START_USER_TIME(1),'(f10.6)', &
    & "  : SYSTEM TIME = ",STOP_SYSTEM_TIME(1)-START_SYSTEM_TIME(1),'(f10.6)',ERR,ERROR,*999)

  ! append a results to results file
  IF(MY_COMPUTATIONAL_NODE_NUMBER==0) THEN
    ! export to cmgui
    FILE="./final"
    METHOD="FORTRAN"
    CALL FIELD_IO_NODES_EXPORT(REGION%FIELDS, FILE, METHOD, ERR,ERROR,*999)  
    CALL FIELD_IO_ELEMENTS_EXPORT(REGION%FIELDS, FILE, METHOD, ERR,ERROR,*999)
!     call SOLID_MECHANICS_IO_WRITE_CMGUI_NODES(FILENAME,REGION,ERR,ERROR,*999)
!     call SOLID_MECHANICS_IO_WRITE_CMGUI_ELEMENTS(FILENAME,REGION,ERR,ERROR,*999)

    ! favour on-the-fly over file I/O, since it can be very large
    IF(COMMAND_ARGUMENT_COUNT()==9) THEN
    open(UNIT=15,FILE='results.log',POSITION='APPEND')
    WRITE(15,'(9f5.1,i8,3F35.20)') Args, number_of_global_dependent_dofs, &
    & dependent_field%variables(1)%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(1), &
    & dependent_field%variables(1)%parameter_sets%parameter_sets(1)%ptr%parameters%cmiss%data_dp(IMPORT_CYLINDER%NER+1), &
    & STOP_USER_TIME(1)-START_USER_TIME(1)
    close(15)
    ENDIF
  ENDIF

! FIELD_IO_ROUTINES don't work yet
! METHOD="FORTRAN"
! call FIELD_IO_NODES_EXPORT (region%FIELDS,FILENAME,METHOD,ERR,ERROR,*999)
! call FIELD_IO_ELEMENTS_EXPORT(REGION%FIELDS,FILENAME,METHOD,ERR,ERROR,*999)

! write(*,*) "adjacent element stuff"
! do i=1,4
!   write(*,*)
!   write(*,'(i2)') i
!   if(allocated(region%meshes%meshes(1)%ptr%topology(1)%ptr%elements%elements(i)%number_of_adjacent_elements)) then
!   write(*,*) region%meshes%meshes(1)%ptr%topology(1)%ptr%elements%elements(i)%number_of_adjacent_elements
!   else
!     write(*,*) "number of adjacent elements is unallocated"
!   endif
!   write(*,*) '------------------------------------------------------------------------------------'
!   if(allocated(region%meshes%meshes(1)%ptr%topology(1)%ptr%elements%elements(i)%adjacent_elements)) then
!   do j=1,size(region%meshes%meshes(1)%ptr%topology(1)%ptr%elements%elements(i)%adjacent_elements,1)
!   write(*,*) region%meshes%meshes(1)%ptr%topology(1)%ptr%elements%elements(i)%adjacent_elements(j,:)
!   enddo
!   else
!     write(*,*) "adjacent elements is unallocated"
!   endif
! enddo

  CALL CMISS_FINALISE(ERR,ERROR,*999)

  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"*** PROGRAM SUCCESSFULLY COMPLETED ******",ERR,ERROR,*999)

  STOP
999 CALL CMISS_WRITE_ERROR(ERR,ERROR)
  STOP

END PROGRAM CYLINDERINFLATIONEXAMPLE

