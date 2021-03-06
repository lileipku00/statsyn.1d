PROGRAM statsyn_TRACKtest
!
!	PROGRAM tracks phonon location and power at each time intervals (nttrack).
! nttrack is an INTEGER and divides the total ammount of time specified into
! "nttrack" equal length time windows.
!

!       ======================================================
!			----- DECLARATIONS -----

      IMPLICIT NONE
      INTEGER, PARAMETER :: nlay0=1000, nt0=144000, nx0=91
      REAL          z(nlay0),vf(nlay0,2),rh(nlay0)
      REAL          z_s(nlay0),r_s(nlay0),vs(nlay0,2)
      REAL          t,x,xo,a,w(nt0)
      CHARACTER*100 IFile,ofile,ofile2
      REAL          dx1,dt1
      INTEGER       irtr1
      INTEGER     :: iz,iz1,itt
			REAL  			:: maxcount
      INTEGER     :: IT,JT,I,J,ic,jj,k,kk,ll,mm
      REAL          p,ang1
      DOUBLE PRECISION wf(nx0,nt0,3)        !STACKED DATA
      REAL          Q(nlay0)              !QUALITY FACTOR 
      REAL          dtstr1                !ATTENUATION PER LAYER
      REAL          mt(nt0)               !SOURCE-TIME FUNCTION 
      COMPLEX       ms(nt0),ss(nx0,nt0)   !SOURCE & STACKED SPECTRA
			REAL          nn(nx0,nt0)
      REAL          pi,P0
		  INTEGER       n180,idelt1,idelt2
		  REAL       :: angst                 !! Starting angle for trace
		  INTEGER		 :: iztrack,ixtrack
      
      ! SOURCE
      REAL          mts(101,4,nt0)        !ATTENUATED SOURCE
      REAL          b(nt0), e(nt0)        !HILBERT TRANSFORM & ENVELOPE
      REAL          mtsc(nt0),datt,dtst1  !SCRATCH SPACE
      INTEGER       ims                   
			
			! ENERGY TRACKING
			CHARACTER*100 :: tfile
			DOUBLE PRECISION,ALLOCATABLE,DIMENSION(:,:,:) :: TC_amp, TC_dt, TC_ds, TC_N !Phonon Tracking array
			REAL			::	attn, minattn
			INTEGER			:: nttrack		!track time points
			INTEGER		::	nttrack_dt						!time interval for saving phonon position
			REAL			::	normfactor						!Normalization factor for cell size

      
      INTEGER       ncaust,icaust         !NUMBER OF CAUSTICS IN A RAY TRACE
      INTEGER       ud
      
      REAL          d2r,re,rm,deg2km
      INTEGER       EorM                  !1=EARTH, 2=MOON
      
      REAL          frac
      REAL          erad
      
      REAL          arp,ars,atp,ats,ar,at !P- & S-WAVE REFL & TRANS COEFS
      REAL          rt_sum,rt_min,rt_max  !MAX & MIN REFL PROBABILITIES
      
      INTEGER       ip,ip0                !1=P, 2=SH, 3=SV
      REAL          x_sign
      
      REAL          scat_depth,scat_prob
      REAL          scat_thet,scat_phi
      REAL          az
      REAL          dp
      REAL        :: d
      REAL        :: delta
      REAL        :: dxi
      REAL        :: h     !! Layer thickness
      INTEGER     :: idum
      INTEGER     :: imth  !! Interpolation method (1 or 2)
      INTEGER     :: iwave !! (P(2) or S(2))
      INTEGER     :: ix,nx ,ixtemp,ixdeg   !! Index & number of distances
      INTEGER     :: nfil  !! Number of filter values for hilbert transform
      INTEGER     :: ntr   !! Number of traces
      INTEGER     :: nts,nts1   !! Number of time series points for source
      INTEGER     :: nitr  !! Number of ith trace (last)
      INTEGER     :: nt    !! Number of time in output file
      INTEGER     :: nlay  !! Number of layers in model
      REAL        :: r0,r1    !! random number 0-1
      REAL        :: pow2,pow1 !! Normalization factor for hilber transform
      REAL        :: s,s1,s2     !! Attenuation & bounds on attenuation for distance
      REAL        :: scr1,scr2,scr3,scr4 !! Flat earth approximation variables
      REAL        :: t0,t1,t2,dti,t_last  !! Time variables (bounds & interval)
      REAL        :: ubot, utop !! Bottom & Top slowness
      REAL        :: x1, x2     !! Distance bounds
      
      REAL           c_mult(3)
      CHARACTER*3    cmp(3)
      REAL           p1,p2(2)              !Ray parameters
      REAL           qdep
      
      INTEGER        status                !I/O ERROR (0=no READ error)
      INTEGER        n_iter_last,it_last,ix_last
      INTEGER     :: nseed
      INTEGER     :: seed
      INTEGER (kind=8)     :: nclock,nclock1
			
			INTEGER     :: normalize !JFBG
!			^^^^^ DECLARATIONS ^^^^^


      write(*,*) 'Last Edited on Feb. 13th 2012 by JFBG'


!       ======================================================
!			----- GET INPUTS -----
      
      WRITE(6,*) 'ENTER SEISMIC VELOCITY MODEL FILE NAME'
      READ (*,'(A)') ifile

25    WRITE(6,'(A)') 'ENTER RAY PARAMETER RANGE (p1, p2(P), p2(S)):'
      READ (5,    *)  p1, p2(1), p2(2)

50    WRITE(6,'(A)') 'ENTER TIME WINDOW & SAMPLING INTERVAL (t1, t2, dt):'
      READ (5, *) t1,t2,dti                    !TIME WINDOW & # OF TIME STEPS
      nt = int((t2-t1)/dti) + 1
      
60    WRITE(6,'(A)') 'ENTER DISTANCE RANGE (x1, x2, nx IN DEGREES):'
      READ (5,    *)  x1, x2, nx              !DISTANCE RANGE & # DISTANCE STEP
      dxi = (x2-x1)/float(nx-1)               !DISTANCE SAMPLING INTERVAL

      WRITE(6,'(A)') 'ENTER NUMBER OF RANDOM TRACES TO LAUNCH:'
      READ (5,    *)  ntr

      WRITE(6,'(A)') 'ENTER EARTHQUAKE DEPTH:'
      READ (5,    *)  qdep
      WRITE(6,*) 'QDEP:',qdep

      WRITE(6,'(A)') 'ENTER 1) EARTH, or 2) MOON:'
      READ (5,    *)  EorM
      WRITE(6,*) 'EorM',EorM

!      WRITE(6,'(A)') 'ENTER 1=P, or 2=SH, 3=SV:'
!      READ (5,    *)  ip0
!      WRITE(6,*) 'HI1:',ip0

      WRITE(6,'(A)') 'ENTER MAX SCATTERING DEPTH:'
      READ (5,    *)  scat_depth
      WRITE(6,*) 'HI2:',scat_depth

      WRITE(6,'(A)') 'ENTER SCATTERING PROBABILITY:'
      READ (5,    *)  scat_prob
			WRITE(6,*) 'SProb:',scat_prob

      WRITE(6,'(A)') 'ENTER TRACK OUTPUT FILE:'
      READ (5,'(A)')  tfile 
			WRITE(6,*) 'Tfile:',tfile
			
			WRITE(6,'(A)') 'ENTER OUTPUT FILE NAME:'!REQUEST OUTPUT FILE NAME
      READ (5,'(A)')  ofile                   !
!			^^^^^ GET INPUTS ^^^^^


!       ======================================================
!			----- INITIALIZE PARAMETERS -----
			
      cmp(1) = 'lpz'
      cmp(2) = 'lpt'
      cmp(3) = 'lpr'
      
      pi = atan(1.)*4.
      re = 6371.
      rm = 1737.
      d2r = pi/180.
      
      nttrack = 5								!Set number of time intervals to track
      nttrack_dt = t2/nttrack
			
      n180 = nint(180/dxi)
	  
	  CALL init_random_seed()

!			^^^^^ INITIALIZE PARAMETERS ^^^^^



!       ======================================================
!			----- PICK MODEL (Earth & Moon) -----						   
      IF (EorM  ==  1) THEN
       deg2km = re*d2r
       erad   = re
      ELSE
       deg2km = rm*d2r
       erad   = rm
      END IF
!			^^^^^ PICK MODEL (Earth & Moon) ^^^^^				
			
			

!       ======================================================
!			----- CONVERT VEL. MODEL TO FLAT EARTH -----

      OPEN(1,FILE=ifile,STATUS='OLD')    !OPEN SEISMIC VELOCITY MODEL
	  
	
      DO I = 1, nlay0                     !READ IN VELOCITY MODEL
       READ(1,*,IOSTAT=status) z_s(i),r_s(i),vs(i,1),vs(i,2),rh(i),Q(i)
	   
!	   write(*,*) z_s(I), Q(I) !JFBG
	   
       IF (status /= 0) EXIT
       CALL FLATTEN_NEW(z_s(i),vs(i,1),z(i),vf(i,1),erad)!FLATTEN VELOCITIES
       CALL FLATTEN_NEW(z_s(i),vs(i,2),z(i),vf(i,2),erad)         
       nlay = I                           !NUMBER OF LAYERS
111   END DO

      CLOSE (1)

      WRITE(6,*) 'NLAY:',nlay
      
      WRITE(6,*) ' '      
      WRITE(6,'(A)')'************************* Table of Model Interfaces' &
      ,'**********************'
      WRITE(6,'(A)')' Depth  Top Velocities  Bot Velocities    -----Flat' & 
      ,'Earth Slownesses-----'
      WRITE(6,'(A)')'             vp1  vs1        vp2  vs2       p1     ' &  
      ,' p2      s1      s2'
      
      DO I = 2, nlay 
       IF (z(i) == z(i-1)) THEN                !ZERO LAYER THICK=DISCONTINUITY
        scr1=1./vf(i-1,1)                      !P-VELOCITY UPPER
        scr2=1./vf(i,1)                        !P-VELOCITY LOWER 
        scr3=999.                              !FLAG IF S VELOCITY = ZERO
        IF (vf(i-1,2) /= 0.) scr3=1./vf(i-1,2) !S-VELOCITY UPPER
        scr4=999.                              !FLAG IF S VELOCITY = ZERO
        IF (vf(i  ,2) /= 0.) scr4=1./vf(i  ,2) !S-VELOCITY LOWER
         WRITE(6,FMT=22) z_s(i),i-1,vs(i-1,1),vs(i-1,2), &
                        i,vs(i,1),vs(i,2),scr1,scr2,scr3,scr4
       END IF
      END DO
22    FORMAT (f6.1,2(i5,f6.2,f5.2),2x,2f9.6,2x,2f9.6)

!			^^^^^^ CONVERT VEL. MODEL TO FLAT EARTH ^^^^^^
			
			
			
			
!       ======================================================
!			----- INITIALIZE TRACKING PARAMETERS -----		
			
			WRITE(6,*) '!!!!!!!!!!!!!!!!!!!!!'	!DEBUG
			WRITE(6,*) ' ',nx,nlay,nttrack			!DEBUG

			!Allocate memory for tracking number of phonons in each area
      ALLOCATE(TC_amp(nx,nlay,nttrack))
			ALLOCATE(TC_dt(nx,nlay,nttrack))
			ALLOCATE(TC_ds(nx,nlay,nttrack))
			ALLOCATE(TC_N(nx,nlay,nttrack)) 
			
      
			
			DO kk = 1,nx
				DO ll = 1,nlay
					DO mm = 1,nttrack
						TC_amp(kk,ll,mm) = 0.
						TC_dt(kk,ll,mm) = 0.
						TC_ds(kk,ll,mm) = 0.
						TC_N(kk,ll,mm) = 0.
					END DO
				END DO
			END DO	
!			^^^^^ INITIALIZE TRACKING PARAMETERS ^^^^^

	

!       ======================================================
!			----- Initialize stacks variable -----			
!      WRITE(6,*) 'ZEROING STACKS:'            !ZERO STACKS
      DO I = 1, nx
       DO J = 1, nt
        DO k = 1, 3
					wf(I,J,k) = 0.
        END DO
       END DO
      END DO
!			^^^^^ Initialize stacks variable ^^^^^	

 
 
!       ======================================================
!			----- Q_i model (Intrinsic attenuation) -----			
!			--- Based on choice of Earth (1) or Moon (2)

!      Use this if Q(i) is not specified in the model file (last column)

!      DO I = 1, nlay+5                      !BUILD Q(z) MODEL
!       Q(I) = 10000.
!       IF ((z_s(I) < 15.).AND.(z_s(i-1) /= 15.) ) THEN
!        Q(I) = 3000.
!       ELSE IF ((z_s(I) < 80.).AND.(z_s(i-1) /= 80.) ) THEN
!        Q(I) = 3000.
!       ELSE IF ((z_s(I) < 220.).AND.(z_s(i-1) /= 220.) ) THEN
!        Q(I) = 3000.
!       ELSE IF ((z_s(I) < 670.).AND.(z_s(i-1) /= 670.) ) THEN
!        Q(I) = 3000.
!       ELSE IF ((z_s(I) < 5149.5).AND.(z_s(i-1) /= 5149.5) ) THEN
!        Q(I) = 3000.
!       ELSE
!        Q(I) = 3000.
!       END IF
!       IF (EorM  ==  2) Q(I) = 10000       !FOR MOON Q IS HIGH UNTIL ??CORE??
!      END DO
!			^^^^^ Q_i model (Intrinsic attenuation) ^^^^^





!       ======================================================
!			----- Find Source Layer -----
      iz1 = 1
      DO WHILE (qdep > z_s(iz1+1))               !FIND WHICH LAYER QUAKE STARTS IN
       iz1 = iz1 +1															 ! FIRST LAYER IS ASSUMED TO BE AT 0km.
      END DO
		  WRITE(6,*) 'DEPTH:',iz1,z_s(iz1)
!			^^^^^ Find Source Layer ^^^^^
      

		

!       ======================================================
!			----- Generate Source Function -----		           
!      WRITE(6,*) 'CALCULATING SOURCE:'        !CALCULATING SOURCE
      pi = atan(1.)*4.                        !
      P0 = dti*4.                             !DOMINANT PERIOD
      nts = nint(P0*4./dti)+1                 !# OF POINTS IN SOURCE SERIES
      IF (nts < 31) nts = 31
      nts1 = 1000
      DO I = 1, nts1
       mt(I) = 0.
      END DO
      DO I = 1, nts                           !SOURCE-TIME FUNCTION
       t0 = dti*float(I-1)-P0
       mt(I) = -4.*pi**2.*P0**(-2.)*(t0-P0/2.) &
               *exp(-2.*pi**2.*(t0/P0-0.5)**2.)
!       WRITE(6,*) t0,mt(i)
      END DO
			
			
      !Calculate maximum source power (i.e. no attenuation) to normalize attn
      minattn = 0.
      DO JJ = 1,nts
        minattn = minattn + mt(JJ)**2/nts
      END DO
			  minattn = minattn**.5;
			 
      WRITE(6,*) '!!!!!!!!!!!!!! MaxSourceRMS ==> ', minattn  !DEBUG
!     ^^^^^ Generate Source Function ^^^^^		           


!       ======================================================
!			----- Attenuation + Attenuated source -----
      datt = 0.02		!  Why 0.02? JFBG
      DO I = 1, 101                           !SOURCES * ATTENUATION
       dtst1 = float(I-1)*datt                !ATTENUATION
       CALL attenuate(mt,mtsc,nts1,dti,dtst1) !
       pow1 = 0.
       DO J = 1, nts1                         !
        mts(I,1,J) =  mtsc(J)                 !
        mts(I,3,J) = -mtsc(J)                 !
        pow1 = pow1 + mtsc(J)**2
       END DO                                 !
       nfil = 5
       CALL TILBERT(mtsc,dti,nts1,nfil,b,e)   !HILBER TRANSFORM (pi/2PHASESHFT)
       pow2 = 0.                              !ZERO POWER OF SERIES
       DO K = 1, nts1                         !COPY HILBERT SERIES TO CORRECT
        mts(I,2,K) = -b(K)                    !
        mts(I,4,K) =  b(K)
        pow2 = pow2 + b(k)**2                 !CUMULATIVE POWER
       END DO
       DO K = 1, nts1                         !NORMALIZE HILBERTS
        mts(I,2,K) = mts(I,2,K)*pow1/pow2     !
        mts(I,4,K) = mts(I,4,K)*pow1/pow2     !
       END DO
      END DO
			
      OPEN(23,FILE='source.out')              !OUTPUT SOURCE
      WRITE(23,*) nts,101                     !
      WRITE(23,FMT=888) 999.99,(datt*float(J-1),J=1,101)
      DO I = 1, nts
        WRITE(23,FMT=888) float(I-1)*dti,(mts(J,2,I)*1.,J=1,101)
      END DO
      CLOSE(23)
 
      OPEN(24,file='mts.out',status='unknown')
        DO I = 1,101
          DO mm = 1,4
            DO K = 1,nts1
              WRITE(24,*) mts(I,mm,K)
		    END DO
          END DO
		END DO
      CLOSE(24)
!			^^^^^ Attenuation ^^^^^			
			
      
			 
			 
!       ======================================================
!   	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!   	!!!!! START OF MAIN RAY TRACING LOOP
!   	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			 
      DO I = 1, ntr   !FOR EACH TRACE -- DOLOOP_001
      
	  ! ============ >>
      ! ----- Initialize Randomization -----			
       CALL SYSTEM_CLOCK(COUNT=nclock)
       seed = (nclock)! + 11 * (/ (k - 1, k = 1, nseed) /)
       CALL srand(seed)
       
	     r0 = rand()    !First rand output not random
                        ! It is seed (clock) dependent
      ! ============ <<
       

								

			iz = iz1		!iz1 is layer in which the source is.
				 
				! ============ >>
				! Pick P- ,SH- or SV- initial phonon state randpmly.
				IF (iz == 1) iwave = 1         ! Surface impact = P-wave only
																						 
				IF (iz /= 1) THEN
					r0 = rand()
					IF (r0 < 1./3.) THEN
						iwave = 1 !P
					ELSE IF ((r0 >= 1./3.).and.(r0 < 2./3.)) THEN
						iwave = 2 !SH
					ELSE 
						iwave = 3 !SV
					END IF
				END IF
				! ============ <<

	   
				! ============ >>
				! Pick take-off angle					 			 
				IF (iwave == 3) iwave = 2			          ! ASSUMING ISOTROPY SO v_SH == v_SV
       
				IF (iz == 1) THEN                       !IF QUAKE STARTS AT SURF GO down
					angst = pi/2.                         !0 - 90 (0 = down)
				ELSE                                    !IF QUAKE AT DEPTH THEN UP OR down
					angst = pi                            !0 - 180 (0 = down)
				END IF                                 
 
        r0 = rand()                            !SELECT RANDOM RAY PARAMETER 
        ang1 = angst*r0                        !Randomly select angle
        ! ============ <<
				
				
        ! ============ >>
        ! Initialize parameters
        t = 0.                                 !SET START TIME = ZERO
        x = 0.                                 !START LOCATION = ZERO
        s = 0.                                 !SET START ATTENUATION = ZERO
        a = 1.                                 !START AMPLITUDE = 1.
        d = 0.                                 !START AT ZERO KM TRAVELED
        x_sign = 1.                            !DISTANCE DIRECTION
				dt1    = 0.														 !time spent in cell
       
        p    = abs(sin(ang1))/vf(iz,iwave)
        az   = 0.
        ! a    = cos(ang1*2.-pi/4.)              !SOURCE AMPLITUDE
		    a = 1.
        ncaust = 0                             !# OF CAUSTICS STARS AT 0.
				
        IF (ang1 < pi/2.) THEN
         ud = 1	
        ELSE
         ud = -1
        END IF
        NITR = 0

        n_iter_last = -999
        ix_last = -999
        it_last = -999
        t_last = 0
        ! ============ <<
			 


			 
			 ! ====================== >>
			 ! Start single ray tracing while loop
			 ! ====================== >>
			 
       DO WHILE ((t < t2).AND.(NITR < 100*nlay)) !TRACE UNTIL TIME PASSES TIME WINDOW - DOLOOP_002
			 
				! ============ >>
				! Track phonon's position
				
			normalize = 0
				
				IF (I < 10000) THEN
				
				IF ((dt1 /= 0.).OR.(NITR == 0)) THEN
				
!				write(*,*) dt1
				
				!IF (t-t_last > 0) THEN
					ixdeg = nint((abs(x)/deg2km-x1))
					ixtemp = ixdeg
					!xo = x1 + float(ixdeg-1)*dxi
					!IF ( abs(xo-abs(x)/deg2km) > 0.1) cycle

					DO WHILE (ixdeg > 360) 
						ixdeg = ixdeg - 360
					END DO
					IF (ixdeg > 180) ixdeg = 180 - (ixdeg-180)
					IF (ixdeg < 0) ixdeg = -ixdeg 
					
					ixtrack = nint(ixdeg/dxi) + 1
					
					
					
					
					itt = nint(t/REAL(nttrack_dt)+.5)
					
				
					! Calculate attenuation
					IT = nint((t       -t1)/dti) + 1		! Time index
					
					ims = int(s/datt)+1
					IF (ims > 100) ims = 100
					IF (ims <=   1) ims =   2
					s1 = float(ims-1)*datt
					s2 = float(ims  )*datt
					frac = (s-s1)/(s2-s1)
					IF (ncaust <= 1) THEN
						icaust = 1
					ELSE
						icaust = ncaust
						DO WHILE (icaust > 4)
							icaust = icaust - 4
						END DO
					END IF
					
					
					! Do RMS of attenuated source at time t
					attn = 0.
					
					DO JJ = 1,nts
					!	attn = attn + ((1.-frac)*mts(ims-1,icaust,JJ) &
          !                + (frac)*mts(ims  ,icaust,JJ) )**2 !Power
					
					  attn = attn + ((1.-frac)*mts(ims-1,icaust,JJ) &
                          + (frac)*mts(ims  ,icaust,JJ))**2/nts ! RMS
					END DO
					attn = attn**.5*dt1 !RMS
					
!					WRITE(6,*) t, attn, frac, ims, icaust !DEBUG
					
!					IF (z_s(iz) - z_s(iz-1) == 0) THEN
!				    iztrack = iz-1
					!	write(*,*) 'YUP!!'
!					ELSE
					  iztrack = iz
!					END IF
					
					IF (itt > nttrack) itt = nttrack
					
					!DEBUG
					!IF ((iztrack > nlay).OR.(ixtrack > nx)) THEN
					!	write(*,*) ixtrack,nx,iztrack,nlay,itt  !DEBUG
					!END IF
					
!					IF (NITR == 0) write(*,*) ixtrack, iz, z_s(iz), iztrack

					TC_amp(ixtrack,iztrack,itt) = TC_amp(ixtrack,iztrack,itt) + attn
					TC_dt(ixtrack,iztrack,itt) = TC_dt(ixtrack,iztrack,itt) + dt1
!					TC_ds(ixtrack,iztrack,itt) = TC_ds(ixtrack,iztrack,itt) + attn
					TC_N(ixtrack,iztrack,itt) = TC_N(ixtrack,iztrack,itt) + 1


					 
				 
				END IF
				END IF

				t_last = t
				! Track phonon's position
				! ============ <<


							

							
                ! ============ >>
                ! SCATTERING LAYER
                NITR = NITR + 1
                r0 = rand()           !RANDOM NUMBER FROM 0 TO 1
       
			 
                IF (z_s(iz) < scat_depth) THEN
                  r0 = rand()
          
                  IF (r0 < scat_prob) THEN
                    r0 = rand()
                    IF (r0 < 0.5) x_sign=-x_sign
			
                    r0 = rand()
                    IF (r0 < scat_prob) ud = -ud
	  
                    r0 = rand()
                    r0 = ( r0 - 0.5 )
                    p = p1 + r0*(1./vf(iz,iwave)-p1)!*scat_prob
            
                  DO WHILE ((p < p1).OR.(p >= 1./vf(iz,iwave)) ) !p2(iwave)))
                    r0 = rand()                       !SELECT RANDOM RAY PARAMETER 
                    ang1 = angst*r0
                    p = abs(sin(ang1))/vf(iz,iwave)
                  END DO
          
                  r0 = rand()                        !
                  r1 = rand()                        !
                  IF (r1 < 0.5) az = az - pi
                    az = az + asin(r0**2)                  !
                    IF (az < -pi) az = az + 2.*pi
                    IF (az >  pi) az = az - 2.*pi
                  END IF 
                
				END IF
				! SCATTERING LAYER
				! ============ <<
				
			
							
				! ============ >>
				! RAY TRACING IN LAYER			
				IF (iz /= 1) THEN
				  IF (abs(vf(iz-1,iwave)) > 0.) THEN
				    utop = 1./vf(iz-1,iwave)              !SLOWNESS AT TOP OF LAYER
				  ELSE
				    utop = 0.
				  END IF 
		
					IF (abs(vf(iz,iwave)) > 0.) THEN
						ubot = 1./vf(iz,iwave)                !SLOWNESS AT BOTTOM OF LAYER
					ELSE
						ubot = 0.
					END IF
         
					h = z(iz)-z(iz-1)                  !THICKNESS OF LAYER
					imth = 2                              !INTERPOLATION METHOD
		
					CALL LAYERTRACE(p,h,utop,ubot,imth,dx1,dt1,irtr1)
					dtstr1 = dt1/Q(iz)                    !t* = TIME/QUALITY FACTOR
				ELSE
					irtr1  = -1
					dx1    = 0.
					dt1    = 0.
					dtstr1 = 0.
				END IF
        
        IF (irtr1 == 0) THEN
         ud = -ud
        ELSE IF (irtr1 >= 1) THEN
         d = d + ((z_s(iz)-z_s(iz-1))**2+dx1**2)**0.5!
         
         t = t + dt1                    !TRAVEL TIME
         x = x + dx1*x_sign*cos(az)     !EPICENTRAL DISTANCE TRAVELED-km
         s = s + dtstr1                 !CUMULATIVE t*
        END IF
        
				IF ( (iz > 1).AND.(abs(irtr1) == 1).AND. &
							(iz < nlay) ) THEN
					IF ( (iz > 1).AND.(iz <= nlay) ) h = z_s(iz)-z_s(iz-1)

          IF (ip  ==  2) THEN
						IF ( (ud == 1) ) THEN               !IF downGOING SH WAVE
							CALL REFTRAN_SH(p,vf(iz-1,2),vf(iz,2),rh(iz-1),rh(iz), &
                           ar,at)
						ELSE IF ((ud == -1) ) THEN          !IF UPGOING SH WAVE
							CALL REFTRAN_SH(p,vf(iz,2),vf(iz-1,2),rh(iz),rh(iz-1), &
                           ar,at)
						END IF
          ELSE
						IF ( (ud == 1) ) THEN               !IF downGOING P-SV WAVE
							CALL RTCOEF2(p,vf(iz-1,1),vf(iz-1,2),rh(iz-1), &
                          vf(iz  ,1),vf(iz  ,2),rh(iz), &
                          ip,arp,ars,atp,ats)
						ELSE IF ((ud == -1) ) THEN          !IF UPGOING P-SV WAVE
							CALL RTCOEF2(p,vf(iz  ,1),vf(iz  ,2),rh(iz  ), &
                          vf(iz-1,1),vf(iz-1,2),rh(iz-1), &
                          ip,arp,ars,atp,ats)           
!           WRITE(6,*) 'HI'
						END IF
          END IF
          
          r0 = rand()                       !RANDOM NUMBER FROM 0 TO 1

          IF (ip  ==  2) THEN                   !IF SH-WAVE

						IF (h > 0.) THEN                    !IF GRADIENT, THEN
							IF (r0 < (abs(ar)/(abs(ar)+abs(at)))/P0**2) THEN!CHECK FOR REFLECTN
								IF (ar < 0) a = -a                !OPPOSITE POLARITY
								ud = -ud                           !downGOING/UPGOING
							END IF                              !
						ELSE                                 !IF INTERFACE THEN
							IF (r0 < (abs(ar)/(abs(ar)+abs(at)))) THEN!CHECK FOR REFLECTION
								IF (ar < 0) a = -a                !OPPOSITE POLARITY
								ud = -ud                           !downGOING/UPGOING
							END IF                              !
						END IF                               !

          ELSE                                  !IF P- OR SV-WAVE 
          	IF (h <= 0.) THEN
							rt_sum = abs(arp)+abs(atp)+abs(ars)+abs(ats)    !SUM OF REFL/TRAN COEFS

							rt_min = 0.                          !RANGE PROBABILITIES FOR P REFL
							rt_max = abs(arp)/rt_sum             !
							IF ( (r0 >= rt_min).AND.(r0 < rt_max) ) THEN!CHECK IF REFLECTED P
								IF (arp < 0) a = -a                 !REVERSE POLARITY
								ud = -ud                            !UPGOING <-> downGOING
								ip = 1                              !P WAVE
							END IF                               !
           
!             IF (z_s(iz) == 137.) WRITE(6,*) arp,atp,r0,ud,ip,a

							rt_min = rt_max                      !RANGE PROBABILITIES 4 SV REFL
							rt_max = rt_max+abs(ars)/rt_sum      !
							IF ( (r0 >= rt_min).AND.(r0 < rt_max) ) THEN!CHECK IF REFLECTED SV
								IF (ars < 0) a = -a                 !REVERSE POLARITY
								ud = -ud                            !UPGOING <-> downGOING
								ip = 3                              !SV WAVE
							END IF                               !

							rt_min = rt_max                      !RANGE PROBABILITIES 4 P TRANS
							rt_max = rt_max+abs(atp)/rt_sum      !
							IF ( (r0 >= rt_min).AND.(r0 < rt_max) ) THEN!CHECK IF TRAMSITTED P
								ip = 1                              !P WAVE
							END IF                               !

							rt_min = rt_max                      !RANGE PROBABILITIES 4 SV TRANS
							rt_max = rt_max+abs(ats)/rt_sum      !
							IF ( (r0 >= rt_min).AND.(r0 <= rt_max) ) THEN!CHECK IF TRANSMITTED SV
								ip = 3                              !SV WAVE
							END IF                               !
						END IF      
          END IF                                !END IF: SH, OR P-SV
         
        ELSE IF (iz == nlay) THEN               !ONCE HIT OTHER SIDE OF CORE
					ud = -ud
					x = x + 180*deg2km
				END IF
	
        
				!FIX NEXT IF FOR DIFFRACTED WAVES: 
				IF (irtr1 == 2) THEN             !RAY TURNS IN LAYER FOLLOW 1 LEN
				ud = -ud
				ncaust = ncaust + 1                   !# OF CAUSTICS
				END IF
				! RAY TRACING IN LAYER	
  			! ============ <<

      
				r0 = rand()	!???
        
				
				
				! ============ >>
				! RECORD IF PHONON IS AT SURFACE
				IF (iz == 1) THEN                      !IF RAY HITS SUFACE THEN RECORD
					ud = 1                                !RAY NOW MUST TRAVEL down

					
					!!ix = nint((abs(x)/deg2km-x1)/dxi) + 1      !EVENT TO SURFACE HIT DISTANCE 
					!!ixtemp = ix
					!!xo = x1 + float(ix-1)*dxi
!					!!WRITE(6,*) xo,abs(x)/deg2km,ix
					!!IF ( abs(xo-abs(x)/deg2km) > 0.1) cycle

					!!DO WHILE (ix > 2*n180)
					!!	ix = ix - 2*n180
					!!END DO
					!!IF (abs(ix) > n180) ix = n180 - (ix-n180)
					!!IF (ix < 1) ix = -ix + 1
					
					
					
					   ix = nint((abs(x)/deg2km-x1)/dxi) + 1      !EVENT TO SURFACE HIT DISTANCE 
							ixtemp = ix
							xo = x1 + float(ix-1)*dxi
							!	 write(6,*) xo,abs(x)/deg2km,ix
							if ( abs(xo-abs(x)/deg2km) > 0.1) cycle
             if (ix > n180) ix = n180 - (ix-n180)
							if (ix < 1) ix = -ix + 1
					
			

					IF (abs(x/deg2km)-abs(x1+dxi*float(ix-1)) > 0.2) CYCLE
					
         
					!IF (x>0.001) WRITE(6,*) x/deg2km,x1+dxi*float(ix-1),ix,dxi
					IT = nint((t       -t1)/dti) + 1 

					ims = int(s/datt)+1
					IF (ims > 100) ims = 100
					IF (ims <=   1) ims =   2
!         ims = 2
					s1 = float(ims-1)*datt
					s2 = float(ims  )*datt
					frac = (s-s1)/(s2-s1)
					IF (ncaust <= 1) THEN
						icaust = 1
					ELSE
						icaust = ncaust
						DO WHILE (icaust > 4)
							icaust = icaust - 4
						END DO
					END IF

					IF ( (IT > 1-nts).and.(IT <= nt0+nts) ) THEN
						IF ( (ip == 1).or.(ip==3) ) THEN
							c_mult(1) = cos(ang1)*cos(az)
							c_mult(2) = sin(ang1)  *sin(az)*0.
							c_mult(3) = sin(ang1)  *cos(az)*.1
						ELSE IF (ip == 2) THEN
							c_mult(1) = 0.!cos(asin(p*vf(iz,iwave)))*sin(az)
							c_mult(2) = cos(ang1)*cos(az)
							c_mult(3) = cos(ang1)*sin(az)
						ELSE IF (ip == 3) THEN
							c_mult(3) = cos(ang1)*cos(az)
							c_mult(2) = cos(ang1)*sin(az)
							c_mult(1) = p*vf(iz,iwave)!*cos(az)
          END IF
					p    = abs(sin(ang1))/vf(iz,2)
!         IF (it>1)WRITE(6,*) ip,iwave,ix,it,a,ang1*180/pi,c_mult(1),c_mult(2),c_mult(3)

          IF((n_iter_last == nitr).and.(ix_last==ix) &
	                           .and.(abs(it_last-it)<5.)) cycle

						n_iter_last = nitr
						ix_last = ix
						it_last = it
						
		
						DO ic = 1, 3
							DO JJ = 1, nts
								JT = IT + JJ - 1
								IF ( (JT > 0).AND.(JT <= nt0).AND.(a /= 0.) ) THEN
									wf(ix,JT,ic) = wf(ix,JT,ic) + a * c_mult(ic) &
                      * (   (1.-frac)*mts(ims-1,icaust,JJ) &
                          + (   frac)*mts(ims  ,icaust,JJ) )!ATTENUATION
								END IF
							END DO
						END DO
					END IF
        END IF
				! RECORD IF PHONON IS AT SURFACE
				! ============ <<
				
				iz = iz + ud                           !GO TO NEXT DEPTH
        
				IF (iz < 1) t = 999999.  !???
			 

			 END DO		!CLOSE SINGLE RAY TRACING LOOP - DOLOOP_002
			 ! ====================== <<
			 ! Close single ray tracing while loop
			 ! ====================== <<			 
			 
			 
			 			 
			 IF (mod(float(I),float(ntr)/20.) == 0) THEN !STATUS REPORT
        WRITE(6,*) nint(float(I)/float(ntr)*100),'% COMPLETE'
			 END IF
      

			END DO	!CLOSE MAIN RAY TRACING LOOP - DOLOOP_001
!   	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!   	!!!!! CLOSE MAIN RAY TRACING LOOP
!   	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!			======================================================

			
!			======================================================
!			----- Output Synthetics -----	
!			wf(1,1,1) = 1.
!      wf(1,1,2) = 1.
!      wf(1,1,3) = 1.
      
!      DO ic = 1, 3
!       ofile2 = trim(ofile)//'.'//cmp(ic)

!       OPEN(22,FILE=trim(ofile2),STATUS='UNKNOWN')    !OPEN OUTPUT FILE
       
!       WRITE(22,*) nt,nx
!       WRITE(22,FMT=888) 999.99,(x1+dxi*float(J-1),J=1,nx)
      
!				DO I = 1, nt
!					DO J = 1, nx
!						IF (abs(wf(J,I,ic)) > 999.9999) wf(J,I,ic) = 999.9999*wf(J,I,ic)/abs(wf(J,I,ic))
!					END DO
!					WRITE(22,FMT=888) t1+float(I-1)*dti,(wf(J,I,ic)*0.1,J=1,nx)
!				END DO

      
!				CLOSE(22)
				
				
!      END DO
!      WRITE(6,*) 'Synthetic outputs done'
!			^^^^^ Output Synthetics ^^^^^
			
      

			
			
			
!			======================================================
!			----- Output Energy Tracking -----
			
			!! NORMALIZE TC variables for cell size ========================
!
!			IF (normalize == 21) THEN
!			
!			DO kk = 1,nlay-1																						   !
!																																		 !
!						normfactor = dxi*pi/360*((r_s(kk))**2-(r_s(kk+1))**2)    !
!																																		 !
!																																		 !
!					IF (normfactor == 0) cycle																 !													 																													 !	
!					trackcount(1:nx,kk,1:nttrack) =	 &												 !
!							trackcount(1:nx,kk,1:nttrack) / normfactor						 !
!			END DO
!			END IF																												 !	
			!! =============================================================
			
			
  		OPEN(17,FILE=tfile,STATUS='UNKNOWN')

			DO kk = 1,nx
					DO mm = 1,nttrack
  						DO ll = 1,nlay
							
						IF (ll > 1) THEN
							IF (z_s(ll) - z_s(ll-1) == 0) cycle
						END IF
						
						WRITE(17,FMT=879) (x1+REAL(kk-1)*dxi),z_s(ll),mm*nttrack_dt, & 
							TC_amp(kk,ll,mm), TC_dt(kk,ll,mm), TC_N(kk,ll,mm)
							
							
!						WRITE(17,FMT=878) (x1+REAL(kk-1)*dxi),z_s(ll),(trackcount(kk,ll))
						
					END DO
				END DO
			END DO
					
			CLOSE(17)
!			^^^^^ Output Energy Tracking ^^^^^

			CLOSE(73) !DEBUG
			

!			======================================================
!			----- Formats -----
878   FORMAT(2(f10.2,1X),f15.5) 
879   FORMAT(2(f10.2,1X),I6,1X,2(F25.15,1X),f10.0)      
888   FORMAT(F10.2,1X,361(F10.6,1X))
!			^^^^^ Formats ^^^^^


			STOP
			END PROGRAM statsyn_TRACKtest
!     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
!     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
!     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
!     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^








!			======================================================
!   	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!   	!!!!! SUBROUTINES
!   	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


SUBROUTINE init_random_seed()
    INTEGER :: i, n, nclock
    INTEGER, DIMENSION(:), ALLOCATABLE :: seed
    n=100000
    CALL RANDOM_SEED(size = n)
    ALLOCATE(seed(n))
         
    CALL SYSTEM_CLOCK(COUNT=nclock)
    seed = nclock + 37 * (/ (i - 1, i = 1, n) /)
    CALL RANDOM_SEED(PUT = seed)
          
    DEALLOCATE(seed)
END SUBROUTINE init_random_seed
      
      
SUBROUTINE attenuate(sin,sout,ndat,dt,tstar)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |THIS SUBROUTINE ATTENUATES AN INPUT SIGNAL (sin) BY A VALUE (tstar) !   !
!   |                                                                    !   !
!   |THIS SUBROUTINE WAS WRITTEN BY JESSE F. LAWRENCE.                   !   !
!   |     CONTACT: jflawrence@stanford.edu                               !   !
!   |                                                                    !   !
!   |AS WITH ALL MY CODES, BEWARE OF THE BUG. NO GUARANTEES! SORRY!      !   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |DECLARE VARIABLES AND SET PARAMETERS:                               !   !
      REAL           sin(*),sout(*),tstar
      INTEGER        ndat,nfreq              !# OF POINTS IN TIME & FREQ DOMAIN
      INTEGER        MAXPTS                  !MAX # OF POINTS & ITERATIONS
      PARAMETER(     MAXPTS = 16384)         !
      REAL           xs(16384)               !SCRATCH SPACE
      COMPLEX        xf(16384),yf(16384)     !SCRATCH SPACE
      REAL           dt,df                   !TIME & FREQ SAMPLING INTERVAL
      REAL           pi                      !SET PI = 3.14....
      REAL           w,dw                    !FREQUCNEY VARIABLES
      REAL           damp
      
      CALL np2(ndat,npts)                    !FIND POWER OF TWO, npts >= ndat
      IF (npts > MAXPTS) THEN               !CHECK THAT ARRAY IS NOT TOO BIG
       WRITE(6,*) 'WARNING: SERIES TRUNCATED TO:',MAXPTS
       npts = MAXPTS
      END IF                                 !
      CALL PADR(sin,ndat+1,npts)             !PAD SERIES WITH ZEROS
      CALL COPYR(sin,xs,npts)                 !COPY INITIAL DENOMINATOR
      
      CALL GET_SPEC(xs,npts,dt,xf,nfreq,df) !GET SPECTRUM OF x
      pi = atan(1.)*4.                       !SET PI = 3.14....
      dw = 2.*pi*df                          !ANGULAR FREQUENCY SAMPLING INTERVAL
      dadw = -tstar*dw                       !DERIVATIVE dA(w)di = -dt*dw
      
      DO I = 1, nfreq                        !APPLY ATTENUATION FILTER
       damp = exp(float(I-1)*dadw)
       w     = dw* float(I-1)                !ANGULAR FREQUENCY
       IF (damp < 0.) damp = 0.
       yf(I) = xf(I)*cmplx(damp,0.)
       yf(I) = yf(I)*exp( cmplx(0.,w*tstar))
      END DO

      CALL GET_TS(yf,nfreq,df,0,sout,npts,dt) !GET TIME SERIES OF ATTENUATED SPEC

      RETURN
END SUBROUTINE attenuate                      !END ATTENUATE
      

SUBROUTINE np2(npts,np)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |THIS SUBROUTINE FINES THE POWER OF TWO THAT IS GREATER THAN OR EQUAL!   !
!   |     TO npts.                                                       !   !
!   |                                                                    !   !
!   |THIS SUBROUTINE WAS WRITTEN BY JESSE F. LAWRENCE.                   !   !
!   |     CONTACT: jflawrence@stanford.edu                               !   !
!   |                                                                    !   !
!   |AS WITH ALL MY CODES, BEWARE OF THE BUG. NO GUARANTEES! SORRY!      !   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      INTEGER     npts,np                      !INPUT & 2^n=np NUMBER OF POINTS
      np = 2                                   !ASSUME STARTING AT 2
      DO WHILE (npts > np)                    !
       np = np * 2                             !KEEP INCREASING SIZE*2 UNTIL BIG
      END DO
      RETURN
      END SUBROUTINE np2                       !END np2


SUBROUTINE COPYR(f1,f2,npts)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |THIS SUBROUTINE COPIES ONE REAL VECTOR TO ANOTHER                   !   !
!   |                                                                    !   !
!   |THIS SUBROUTINE WAS WRITTEN BY JESSE F. LAWRENCE.                   !   !
!   |     CONTACT: jflawrence@stanford.edu                               !   !
!   |                                                                    !   !
!   |AS WITH ALL MY CODES, BEWARE OF THE BUG. NO GUARANTEES! SORRY!      !   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      INTEGER     I,npts                       !STEP & NUMBER OF POINTS
      REAL        f1(*),f2(*)                  !INPUT AND OUTPUT SERIES
      DO I = 1, npts                           !
       f2(I) = f1(I)                           !COPY POINTS
      END DO
      
      RETURN
END SUBROUTINE copyr                           !END COPYR

      
SUBROUTINE PADR(f1,n1,n2)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |THIS SUBROUTINE COPIES ONE REAL VECTOR TO ANOTHER                   !   !
!   |                                                                    !   !
!   |THIS SUBROUTINE WAS WRITTEN BY JESSE F. LAWRENCE.                   !   !
!   |     CONTACT: jflawrence@stanford.edu                               !   !
!   |                                                                    !   !
!   |AS WITH ALL MY CODES, BEWARE OF THE BUG. NO GUARANTEES! SORRY!      !   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      INTEGER     I,n1,n2                      !STEP, START & END POINTS
      REAL        f1(*)                        !SERIES TO ADD ZEROS TO
      DO I = n1, n2                            !
       f1(I) = 0.                              !MAKE ZERO
      END DO
      RETURN
END SUBROUTINE padr                            !END PADR
      
      

SUBROUTINE REFTRAN_SH(p,b1,b2,rh1,rh2,ar,at)
      REAL       p,ar,at
      REAL       pi,j1,j2,b1,rh1,rh2
      pi   = atan(1.)*4.
      r2d = 180./pi
      IF (p*b1 <= 1.) THEN
       j1   = asin(p*b1)
      ELSE
       j1 = pi/2.
      END IF
      IF (p*b2 <= 1.) THEN
       j2   = asin(p*b2)
      ELSE
       j2   = pi/2. 
      END IF
      
      DD   = rh1*b1*cos(j1)+rh2*b2*cos(j2)

      ar   = (rh1*b1*cos(j1)-rh2*b2*cos(j2))/DD
      at   = 2.*rh1*b1*cos(j1)/DD
      
      RETURN
END SUBROUTINE REFTRAN_SH



! SUBROUTINE RTCOEF calculates reflection/transmission coefficients
! for interface between two solid layers, based on the equations on 
! p. 150 of Aki and Richards.
!
!  Inputs:    vp1     =  P-wave velocity of layer 1 (top layer)
!  (REAL)     vs1     =  S-wave velocity of layer 1
!             den1    =  density of layer 1
!             vp2     =  P-wave velocity of layer 2 (bottom layer)
!             vs2     =  S-wave velocity of layer 2
!             den2    =  density of layer 2
!             pin     =  horizontal slowness (ray PARAMETER)
!             PorS    =  1=P-WAVE, 3=SV-WAVE
!  Returns:   arp     =  down P to P up     (refl)
!  (COMPLEX)  ars     =  down P to S up     (refl)
!             atp     =  down P to P down   (tran)
!             ats     =  down P to S down   (tran)
!   OR:
!             arp     =  down S to P up     (refl)
!             ars     =  down S to S up     (refl)
!             atp     =  down S to P down   (tran)
!             ats     =  down S to S down   (tran)
!
! NOTE:  All input variables are REAL.  
!        All output variables are COMPLEX!
!        Coefficients are not energy normalized.
!
SUBROUTINE RTCOEF2(pin,vp1,vs1,den1,vp2,vs2,den2,pors, &
                         rrp,rrs,rtp,rts)
      IMPLICIT     NONE
      REAL         vp1,vs1,den1,vp2,vs2,den2     !VELOCITY & DENSITY
      INTEGER      pors                          !P (1) OR S (2)                          
      COMPLEX      a,b,c,d,e,f,g,H               !TEMPORARY VARIABLES
      COMPLEX      cone,ctwo                     !COMPLEX  = 1 OR = 2
      COMPLEX      va1,vb1,rho1,va2,vb2,rho2     !VELOCITY & DENSITY (COMPLEX)
      REAL         pin                           !INPUT SLOWNESS
      COMPLEX      p                             !INPUT SLOWNESS (P OR S)
      COMPLEX      si1,si2,sj1,sj2               !SIN OF ANGLE
      COMPLEX      ci1,ci2,cj1,cj2               !COMPLEX SCRATCH
      COMPLEX      term1,term2                   !COMPLEX SCRATCH
      COMPLEX      DEN                           !DENOMINATOR
      COMPLEX      trm1,trm2                     !COMPLEX SCRATCH
      COMPLEX      arp,ars,atp,ats               !REFLECTION & TRANSMISSION COEFS
      REAL         rrp,rrs,rtp,rts               !REFLECTION & TRANSMISSION COEFS
      
      va1    = cmplx(vp1,  0.)                   !MAKE VEL & DENSITY COMPLEX
      vb1    = cmplx(vs1,  0.)
      rho1   = cmplx(den1, 0.)
      va2    = cmplx(vp2,  0.)
      vb2    = cmplx(vs2,  0.)
      rho2   = cmplx(den2, 0.)

      p      = cmplx(pin,  0.)                   !MAKE RAY PARAMETER COMPEX      
      
      cone   = cmplx(1.,0.)                      !COMPLEX 1 & 2
      ctwo   = cmplx(2.,0.)
      
      si1    = va1 * p                           !SIN OF ANGLE
      si2    = va2 * p          
      sj1    = vb1 * p
      sj2    = vb2 * p       
!
      ci1    = csqrt(cone-si1**2)                !
      ci2    = csqrt(cone-si2**2)
      cj1    = csqrt(cone-sj1**2)
      cj2    = csqrt(cone-sj2**2)         
!
      term1  = (cone-ctwo*vb2*vb2*p*p)
      term2  = (cone-ctwo*vb1*vb1*p*p)
      
      a      = rho2*term1-rho1*term2
      b      = rho2*term1+ctwo*rho1*vb1*vb1*p*p
      c      = rho1*term2+ctwo*rho2*vb2*vb2*p*p
      d      = ctwo*(rho2*vb2*vb2-rho1*vb1*vb1)
      E      = b*ci1/va1+c*ci2/va2
      F      = b*cj1/vb1+c*cj2/vb2
      G      = a-d*ci1*cj2/(va1*vb2)
      H      = a-d*ci2*cj1/(va2*vb1)
      DEN    = E*F+G*H*p*p
!
      IF (PorS  ==  1) THEN
       trm1   = b*ci1/va1-c*ci2/va2          
       trm2   = a+d*ci1*cj2/(va1*vb2)
       arp    = (trm1*F-trm2*H*p*p)/DEN           !refl down P to P up
       trm1   = a*b+c*d*ci2*cj2/(va2*vb2)       
       ars    = (-ctwo*ci1*trm1*p)/(vb1*DEN)      !refl down P to S up
       atp    = ctwo*rho1*ci1*F/(va2*DEN)         !trans down P to P down
       ats    = ctwo*rho1*ci1*H*p/(vb2*DEN)       !trans down P to S down
      ELSE
       trm1   = a*b+c*d*ci2*cj2/(va2*vb2)       
       arp    = (-ctwo*cj1*trm1*p)/(va1*DEN)      !refl down S to P up
       trm1   = b*cj1/vb1-c*cj2/vb2               
       trm2   = a+d*ci2*cj1/(va2*vb1)
       ars    = -(trm1*E-trm2*G*p*p)/DEN          !refl down S to S up
       atp    = -ctwo*rho1*cj1*G*p/(va2*DEN)      !trans down S to P down 
       ats    = ctwo*rho1*cj1*E/(vb2*DEN)         !trans down S to S down
      END IF
      
      rrp = REAL(arp)!**2+imag(arp)**2)**0.5
      rrs = REAL(ars)!**2+imag(ars)**2)**0.5
      rtp = REAL(atp)!**2+imag(atp)**2)**0.5
      rts = REAL(ats)!**2+imag(ats)**2)**0.5
      
!      WRITE(6,*) 'HI1:',a,b,c,d,E,F,G,H,DEN
      
      RETURN
END SUBROUTINE rtcoef2




SUBROUTINE FLATTEN(z_s,vs,z_f,vf_f)
!   !FLATTEN calculates flat earth transformation.
      erad=6371.
      r=erad-z_s
      z_f=-erad*alog(r/erad)
      vf_f=vs*(erad/r)
      RETURN
END SUBROUTINE flatten

SUBROUTINE FLATTEN_NEW(z_s,vs,z_f,vf_f,erad)
      REAL     z_s,z_f,vf_f,vs,erad,r
      r=erad-z_s
      z_f=-erad*alog(r/erad)
      vf_f=vs*(erad/r)
      RETURN
END SUBROUTINE FLATTEN_NEW

SUBROUTINE LAYERTRACE(p,h,utop,ubot,imth,dx,dt,irtr)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   ! LAYERTRACE calculates the travel time and range offset
!   ! for ray tracing through a single layer.
!   !
!   ! Input:    p     =  horizontal slowness
!   !           h     =  layer thickness
!   !           utop  =  slowness at top of layer
!   !           ubot  =  slowness at bottom of layer
!   !           imth  =  interpolation method
!   !                    imth = 1,  v(z) = 1/sqrt(a - 2*b*z)
!   !                         = 2,  v(z) = a - b*z
!   !                         = 3,  v(z) = a*exp(-b*z)
!   !
!   ! RETURNs:  dx    =  range offset
!   !           dt    =  travel time
!   !           irtr  =  RETURN code
!   !                 = -1,  zero thickness layer
!   !                 =  0,  ray turned above layer
!   !                 =  1,  ray passed through layer
!   !                 =  2,  ray turned within layer, 1 segment counted in dx,dt
!   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      IF (h == 0.) THEN      !check for zero thickness layer
         dx=0.
         dt=0.
         irtr=-1
         RETURN         
      END IF
!   !
      u=utop
      y=u-p
      IF (y <= 0.) THEN   !COMPLEX vertical slowness
         dx=0.            !ray turned above layer
         dt=0.
         irtr=0
         RETURN
      END IF
!
      q=y*(u+p)
      qs=sqrt(q)
!   ! special FUNCTION needed for integral at top of layer
      IF (imth == 2) THEN
         y=u+qs
         IF (p /= 0.) y=y/p
         qr=alog(y)
      ELSE IF (imth == 3) THEN
         qr=atan2(qs,p)
      END IF      
!
      IF (imth == 1) THEN
          b=-(utop**2-ubot**2)/(2.*h)
      ELSE IF (imth == 2) THEN
          vtop=1./utop
          vbot=1./ubot
          b=-(vtop-vbot)/h
      ELSE
          b=-alog(ubot/utop)/h
      END IF  
!
      IF (b == 0.) THEN     !constant velocity layer
         b=-1./h
         etau=qs
         ex=p/qs
         go to 160
      END IF
!   !integral at upper limit, 1/b factor omitted until END
      IF (imth == 1) THEN
         etau=-q*qs/3.
         ex=-qs*p
      ELSE IF (imth == 2) THEN
         ex=qs/u
         etau=qr-ex
         IF (p /= 0.) ex=ex/p
      ELSE
         etau=qs-p*qr
         ex=qr
      END IF
!   ! check lower limit to see IF we have turning point
      u=ubot
      IF (u <= p) THEN   !IF turning point,
         irtr=2          !THEN no contribution
         go to 160       !from bottom point
      END IF 
      irtr=1
      q=(u-p)*(u+p)
      qs=sqrt(q)
!
      IF (imth == 1) THEN
         etau=etau+q*qs/3.
         ex=ex+qs*p
      ELSE IF (imth == 2) THEN
         y=u+qs
         z=qs/u
         etau=etau+z
         IF (p /= 0.) THEN
            y=y/p
            z=z/p
         END IF
         qr=alog(y)
         etau=etau-qr
         ex=ex-z
      ELSE
         qr=atan2(qs,p)
         etau=etau-qs+p*qr
         ex=ex-qr
      END IF      
!
160   dx=ex/b
      dtau=etau/b
      dt=dtau+p*dx     !convert tau to t
!
      RETURN
END SUBROUTINE layertrace





SUBROUTINE NPOW2(npts,np)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |THIS SERIES DETERMINES THE POWER OF TWO THAT IS EQUAL OR JUST       !   !
!   |     GREATER THAN THE NUMBER OF POINTS SUPPLIED:                    !   !
      INTEGER npts,np
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      np = 0
      DO WHILE (2**np < npts)
       np = np + 1
      END DO

      RETURN
END SUBROUTINE npow2 



SUBROUTINE TILBERT(a,dt,npts,nfil,b,e)
!   | --- --------- --------- --------- --------- --------- --------- -- |   !
! of time series in the time domain.
!     Inputs:   a    =  time series
!               dt   =  time spacing
!               npts =  number of points in a
!               nfil =  half-number of points in filter
!     RETURNs:  b    =  Hilbert transform of time series
!               e    =  envelope time FUNCTION
!
!   | --- --------- --------- --------- --------- --------- --------- -- |   !
      REAL       a(*),b(*),e(*),h(2001)
      REAL       dt
      INTEGER    npts,nfil,nfiltot,I,J,II,JJ,i1,i2
      SAVE       dt0,npts0,h,nfiltot             !STORE VARIABLES TO SAVE TIME
      pi = atan(1.)*4.                           !SET PI = 3.14.....

      IF ( (dt /= dt0).and.(npts /= npts0)) THEN !SET UP THE FILTER
       nfiltot = 2*nfil+1                        !# OF POINTS IN FILTER
       DO 10 i = 1, nfiltot                      !FOR EACH FILTER POINT
        t=float(i-nfil-1)*dt                     !TIME OF ITH POINT
        IF (i /= nfil+1) THEN                    !CALCULATE FILTER
         h(i) = -1./(pi*t)
        ELSE                                     !AVOID SINGULARITY
         h(i) = 0.
        END IF
10     END DO
       CALL TAPERR(h,nfiltot,0.5,0.5)
       dt0     = dt                              !STORE SAMPLING INTERVAL
       npts0   = npts                            !STORE NUMBER OF POINTS
      END IF

      CALL ZEROR(e,npts)                         !ZERO ENVELOPE
      CALL ZEROR(b,npts)                         !ZERO HILBERT TRANSFORM

      i1 = 1 + nfil
      i2 = npts - nfil
      DO 50 i=i1,i2
       DO 40 j = 1, nfiltot
        ii  = i - (j-nfil-1)
        b(i)= b(i)+a(ii)*h(j)
40     END DO
       b(i)=b(i)*dt
50    END DO
      DO 70 i=i1,i2
       e(i) = ( (a(i)**2+b(i)**2) )**0.5
70    END DO
      RETURN
END SUBROUTINE TILBERT







SUBROUTINE TAPERR(S1,ndat,tap1,tap2)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   | THIS SUBROUTINE TAPERS ANY SIGNAL (S1), OF LENGTH npts, FROM 1 TO  !   ! 
!   |      tap1*npts, AND FROM tap2*npts TO npts.                        !   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      REAL       S1(*),tap1,tap2,PI,cs
      INTEGER    tap1n,tap2n
      INTEGER    I,ndat
      PI = atan(1.0)*4.
      tap1n = nint(tap1*float(ndat))                 !INTEGER TAPER POINT 1
      tap2n = nint(tap2*float(ndat))                 !INTEGER TAPER POINT 2

      DO I = 1, tap1n                                !TAPER FROM 1 TO POINT 1
         cs     = sin(float(I-1)*PI/float(tap1n-1)/2.)
         S1(I)  = S1(I) * cs**2
      END DO
      DO I = 1, tap2n                                !TAPER FROM POINT 2 TO END
         cs     = sin(float(I-1)*PI/float(tap2n-1)/2.)
         S1(ndat-I+1)  = S1(ndat-I+1) * cs**2
      END DO

      RETURN
END SUBROUTINE taperr


SUBROUTINE ZEROR(series,npts)
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
!   |THIS SUBROUTINE ZEROES ANY 1D SERIES OF LENGTH TO POINT, npts:      !   !
!   | --- --------- --------- --------- --------- --------- --------- -- !   !
      REAL series(*)
      INTEGER npts

      DO I = 1, npts
       series(I) = 0.
      END DO

      RETURN
END SUBROUTINE zeror

SUBROUTINE usph2car(lon,lat,x1,y1,z1)
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   !THIS SUBROUTINE CONVERTS SPHERICAL COORDINATES (LON,LAT) (RADIAN) TO!   !
!   !     CARTESIAN COORDINATES (X,Y,Z), WITH RADIUS = 1.                !   !
!   !                                                                    !   !
!   !THIS SUBROUTINE WAS WRITTEN BY JESSE F. LAWRENCE.                   !   !
!   !    CONTACT: jflawrence@stanford.edu                                !   ! 
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   ! DECLARE VARIABLES:                                                 !   !
      REAL    ::  lon,lat                  !LOCATION (SPHERICAL)
      REAL    ::  x1,y1,z1                 !LOCATION (CARTESIAN)
      
      x1 = cos(lat) * cos(lon)             !CARTESIAN POSITION
      y1 = cos(lat) * sin(lon)             !
      z1 = sin(lat)                        !
      
      RETURN                               !
END SUBROUTINE usph2car                    !END LON_LAT_X_Y_Z
      
      
      
      
      
SUBROUTINE ucar2sphr(x1,x2,x3,lon,lat)
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   !THIS SUBROUTINE CONVERSTS TO LATITUDE AND LONGITUDE.  THE SUB   !   !
!   !     ASSUMES THAT THE COORDINATE IS AT THE SURFACE.             !   !
!   !     OUTPUTS ARE IN RADIANS:                                    !   !
!   !                                                                    !   !
!   !THIS SUBROUTINE WAS WRITTEN BY JESSE F. LAWRENCE.                   !   !
!   !    CONTACT: jflawrence@stanford.edu                                !   ! 
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   ! DECLARE VARIABLES:                                                 !   !
      REAL      lon,lat,x1,x2,x3,pi
      pi = atan(1.)*4.                          !SET PI = 3.14....
      lat = arsin(x3)                           !
      IF (x1 == 0.) THEN
       IF (x2 > 0.) lon = pi / 2.
       IF (x2 < 0.) lon = 3. * pi / 2.
      ELSE
       lon = atan(x2 / x1)
       IF (x1 < 0.) lon = lon + pi
       IF ( (x1 > 0.).AND.(x2 < 0.) )	lon = lon + 2. * pi
      END IF
      
      RETURN                                    !
END SUBROUTINE ucar2sphr                                      !END UCAR2SPHD
      

SUBROUTINE dist_two_angles(lon1,lat1,lon2,lat2,angdist)
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   !THIS SUBROUTINE USES angdis TO DETERMINE THE DISTANCE TWO POINTS    !   !
!   !     GIVEN LONGITUDE, LATITUDE FOR EACH POINT ALL IN DEGREES.       !   !
!   !     THIS SUBROUTINE DOES ALL THE RADIAN TO DEGREE CONVERSIONS.     !   !
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
      REAL    ::  lat1,lon1,lat2,lon2,angdist
      REAL    ::  x1,x2,x3,y1,y2,y3
      REAL    ::  pi,arcos

      IF (lat1 /= lat2) THEN
       IF  (abs(lon1-lon2)/abs(lat1-lat2) < 0.02) THEN
        angdist = abs(lat1-lat2)
        RETURN
       END IF
      END IF

      CALL USPH2CAR(lon1,lat1,x1,x2,x3)
      CALL USPH2CAR(lon2,lat2,y1,y2,y3)
      angdist = abs(arcos(x1*y1 + x2*y2 + x3*y3))

      RETURN
END SUBROUTINE dist_two_angles

      
   
REAL FUNCTION arcos(a)
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   !THIS FUCTION DETERMINES THE ARC COSINE OF AN ANGLE (a):             !   !
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
      IMPLICIT     NONE
      REAL      :: a, aa, pi, pi2,artan2
      aa = 1D0-a*a
      pi = atan(1.)*4D0
      pi2 = pi/2D0
      
      IF (aa > 0) THEN
       arcos = artan2(sqrt(aa),a)
      ELSE
       arcos = pi2-sign(pi2,a)
      END IF
      RETURN
END FUNCTION arcos



REAL FUNCTION arsin(a)
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   !THIS FUCTION DETERMINES THE ARC SINE OF AN ANGLE (a):               !   !
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
      IMPLICIT      NONE
      REAL      ::  a, aa, pi, pi2
      aa = 1.-a*a
      pi = atan(1.)*4D0
      pi2 = pi/2D0
      IF (aa > 0) THEN
       arsin = atan(a/sqrt(aa))
      ELSE
       arsin = sign(pi2,a)
      END IF
      RETURN
END FUNCTION arsin
      
      
      
REAL FUNCTION artan2(y,x)
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
!   !THIS FUCTION DETERMINES THE ARC TANGENT OF AN ANGLE (X AND Y):     !   !
!   !     THIS VERSION OF ARCTAN DOES NOT CHOKE AT (0,0):               !   !
!   ! --- --------- --------- --------- --------- --------- --------- -- !   !
      IMPLICIT        NONE
      REAL        ::  y,x,sign, pi, pi2
      pi = atan(1.)*4D0
      pi2 = pi/2D0
      IF (x == 0) THEN
       artan2 = sign(pi2,y)
      ELSE
       artan2 = atan(y/x)
       IF (x < 0) THEN
        artan2 = artan2+sign(pi,y)
       END IF
      END IF
      RETURN
END FUNCTION artan2

