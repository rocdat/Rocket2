MODULE SURFACE_MODULE_3D
    IMPLICIT NONE
    
    REAL(8), PARAMETER :: MINERROR = 1E-16, PI = 3.141592653589793238, MINLOCERROR = 1E-2, MINNORMERROR = 5E-2
    
    REAL(8) :: DOMAIN_MAX(3), DOMAIN_MIN(3)
    
    REAL(8) :: MODEL_ANGLE, MODEL_AXIS_EQN(4,2)
    
    INTEGER :: SURFACE_AREA_ITER
    INTEGER :: SURFACE_PRESSURE_ITER	
    REAL(8) :: SURFACE_TOTAL_TIME
    REAL(8) :: SURFACE_TIME_STEP
    REAL(8) :: SURFACE_AREA_ARRAY(100000)
    REAL(8) :: TOTAL_PRESSURE_ARRAY(100000,3)
    INTEGER :: SURFACE_FLAG_ARRAY(100000,10)
    INTEGER :: RESTART_FLAG
    INTEGER :: RESTART_ITERATION
    REAL(8) :: CHI_C_LOW, CHI_C_HIGH
    REAL(8) :: INTERFACE_THRESHOLD
    INTEGER :: SMALL_REGION_POINT_NUM
    REAL(8) :: THIN_REGION_EXISTENCE
    REAL(8) :: THIN_REGION_ATTACHMENT
    REAL(8) :: EDGE_SPLITTING
    REAL(8) :: EDGE_COLLAPSING
    INTEGER :: SURFACE_MOVING_TYPE
    INTEGER :: ZIPPER_FLAG
    
    TYPE SURFACE_TYPE
        
        REAL(8) :: MESH_SIZE
        REAL(8) :: MESH_SIZE_MAX
        REAL(8) :: HASH_SIZE
        REAL(8), ALLOCATABLE :: SURFACE_POINTS(:,:)
        INTEGER :: SURFACE_POINTS_NUM
        INTEGER, ALLOCATABLE :: SURFACE_FACES(:,:)
        INTEGER :: SURFACE_FACES_NUM
	INTEGER :: SURFACE_PATCHES_NUM
	INTEGER, ALLOCATABLE :: SURFACE_PATCHES_TOPCHANGE_TYP(:)
        
        REAL(8), ALLOCATABLE :: SURFACE_INITIAL_FACE_AREA(:)
        REAL(8), ALLOCATABLE :: SURFACE_INITIAL_EDGE_LENGTH(:,:)
	REAL(8), ALLOCATABLE :: SURFACE_INITIAL_MESH_QUALITY(:)
        
        REAL(8), ALLOCATABLE :: FACE_B_RATE(:)
        REAL(8), ALLOCATABLE :: POINT_VELOCITY(:,:)
        REAL(8), ALLOCATABLE :: POINT_DISPLACEMENT(:,:)
        INTEGER, ALLOCATABLE :: POINT_FACE_CONNECTION(:,:)
        INTEGER, ALLOCATABLE :: POINT_FACE_CONNECTION_NUM(:)
        INTEGER, ALLOCATABLE :: POINT_TYPE(:)
	INTEGER, ALLOCATABLE :: INITIAL_POINT_TYPE(:)
        
        INTEGER, ALLOCATABLE :: FACE_LOCATION(:)
        INTEGER, ALLOCATABLE :: FACE_ONINTERFACE(:)
        
        INTEGER, ALLOCATABLE :: POINT_RELATEDPT(:,:)
        INTEGER, ALLOCATABLE :: POINT_RELATEDFACE(:,:)
        
        REAL(8), ALLOCATABLE :: FACE_PRESSURE(:)
        REAL(8), ALLOCATABLE :: POINT_FORCE(:,:)
        REAL(8), ALLOCATABLE :: POINT_DISTANCE(:,:)
        
        INTEGER, ALLOCATABLE :: FACE_IMPACT_ZONE(:,:)
	INTEGER, ALLOCATABLE :: FACE_ABLATION_FLAG(:)
        
        INTEGER, ALLOCATABLE :: FACE_DIVIDED_REGION_ARRAY(:)
        INTEGER :: FACE_DIVIDED_REGION_NUM
        INTEGER, ALLOCATABLE :: FACE_DIVIDED_BOUNDARY_ARRAY(:,:)
        INTEGER :: FACE_DIVIDED_BOUNDARY_NUM
        
        INTEGER, ALLOCATABLE :: RIDGE_NUM(:)
        INTEGER, ALLOCATABLE :: RIDGE(:,:)
        
    END TYPE SURFACE_TYPE
    
    TYPE(SURFACE_TYPE), TARGET :: SURFACE_FLUID
    TYPE(SURFACE_TYPE), TARGET :: SURFACE_PROPEL
    TYPE(SURFACE_TYPE), TARGET :: SURFACE_CASE
    
    INTEGER :: INTERFACE_FLUID_POINTS_NUM
    REAL(8), ALLOCATABLE, TARGET :: INTERFACE_FLUID_POINTS(:,:)
    INTEGER, ALLOCATABLE, TARGET :: INTERFACE_FLUID_POINTS_LOC(:,:)
    INTEGER :: INTERFACE_FLUID_FACES_NUM
    INTEGER, ALLOCATABLE, TARGET :: INTERFACE_FLUID_FACES(:,:)
    INTEGER, ALLOCATABLE, TARGET :: INTERFACE_FLUID_FACES_LOC(:,:)
    
    INTEGER :: INTERFACE_STRUCT_POINTS_NUM
    REAL(8), ALLOCATABLE, TARGET :: INTERFACE_STRUCT_POINTS(:,:)
    INTEGER, ALLOCATABLE, TARGET :: INTERFACE_STRUCT_POINTS_LOC(:,:)
    INTEGER :: INTERFACE_STRUCT_FACES_NUM
    INTEGER, ALLOCATABLE, TARGET :: INTERFACE_STRUCT_FACES(:,:)
    INTEGER, ALLOCATABLE, TARGET :: INTERFACE_STRUCT_FACES_LOC(:,:)
    

    CONTAINS
    
    SUBROUTINE DISTANCE_FACE_POINT(V,W1,W2,W3,     D)
    
        REAL(8) :: V(3),W1(3),W2(3),W3(3),S(3)
	REAL(8) :: A(3), B(3),C(3)
        REAL(8) :: U,T,D
        
	A = W2 - W1 
	B = W3 - W1
	C = V - W1
        CALL VEC_CURL1(A,B,S)
        T = SQRT(DOT_PRODUCT(S,S))
        U = DOT_PRODUCT(S,C)
        D = ABS(U)/T
    
    END SUBROUTINE
    
    SUBROUTINE DISTANCE_LINE_POINT(V,W1,W2,     D) 
        REAL(8) :: V(3),W1(3),W2(3),VEC(3)
        REAL(8) :: L2,INNER,D,NORM
        
        L2 = DOT_PRODUCT(W2-W1,W2-W1)
        NORM = SQRT(L2)
        INNER = DOT_PRODUCT(W1-V,W2-W1)
        VEC = W1 - V - INNER/L2 * (W2-W1)
        D = SQRT(DOT_PRODUCT(VEC,VEC))
    
    END SUBROUTINE DISTANCE_LINE_POINT
    
    SUBROUTINE MINMOD(A,B,      T)
        REAL(8) :: A,B,T
        INTEGER :: S1,S2
    
        CALL SIGN1(A,S1)
        CALL SIGN1(B,S2)
        T = (S1+S2)/2 * MIN(ABS(A),ABS(B))
        
    END SUBROUTINE MINMOD
    
    SUBROUTINE SIGN1(A,       T)
        REAL(8) :: A 
        INTEGER :: T
    
        IF(A.LT.0.0) THEN 
            T=-1
    
        ELSE IF(A.EQ.0.0) THEN
            T=0
  
        ELSE 
            T=1
        END IF
  
    END SUBROUTINE SIGN1
    
    SUBROUTINE SIGN2(R,DX,       T)
        REAL(8) :: R,DX
        REAL(8) :: T
        
        T = R/SQRT(R**2 + DX**2)
  
    END SUBROUTINE SIGN2
    
    SUBROUTINE VEC_CURL1(V,W,       R) ! DIM=3 
        REAL(8) :: V(3),W(3),R(3)

        R(1) = V(2)*W(3) - V(3)*W(2)
        R(2) = V(3)*W(1) - V(1)*W(3)
        R(3) = V(1)*W(2) - V(2)*W(1)
        
    END SUBROUTINE VEC_CURL1
    
    SUBROUTINE VEC_CURL2(V1,V2,W1,W2,       R) ! DIM=3 
        REAL(8) :: V1(3),V2(3),W1(3),W2(3),R(3)

        R(1) = (V2(2)-V1(2))*(W2(3)-W1(3)) - (V2(3)-V1(3))*(W2(2)-W1(2))
        R(2) = (V2(3)-V1(3))*(W2(1)-W1(1)) - (V2(1)-V1(1))*(W2(3)-W1(3))
        R(3) = (V2(1)-V1(1))*(W2(2)-W1(2)) - (V2(2)-V1(2))*(W2(1)-W1(1))

    END SUBROUTINE VEC_CURL2
    
    SUBROUTINE TRIANGLE_NORMAL(P1, P2, P3,       N)
	IMPLICIT NONE
        REAL(8) :: P1(3), P2(3), P3(3), N(3), V1(3), V2(3)
        
        V1 = P2-P1
        V2 = P3-P1
        
        CALL VEC_CURL1(V1,V2,N)
    END SUBROUTINE TRIANGLE_NORMAL
    
    SUBROUTINE INIT_RANDOM_SEED()

        IMPLICIT NONE
        
        INTEGER :: I, N, CLOCK
        INTEGER, DIMENSION(:), ALLOCATABLE :: SEED
        CALL RANDOM_SEED(SIZE = N)
        ALLOCATE(SEED(N))
        CALL SYSTEM_CLOCK(COUNT=CLOCK)
        SEED = CLOCK + 37*(/(I-1, I=1, N)/)
        CALL RANDOM_SEED(PUT = SEED)
        DEALLOCATE(SEED)

    END SUBROUTINE INIT_RANDOM_SEED
    
    
END MODULE SURFACE_MODULE_3D
