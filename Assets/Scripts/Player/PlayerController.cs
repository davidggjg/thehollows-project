using UnityEngine;

/// <summary>
/// Third-person over-the-shoulder player controller.
/// SETUP: CharacterController on same GO, "CameraTarget" child transform at shoulder,
/// a Light component child assigned to flashlightObject.
/// </summary>
[RequireComponent(typeof(CharacterController))]
public class PlayerController : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] private float walkSpeed   = 3.0f;
    [SerializeField] private float sprintSpeed = 5.8f;
    [SerializeField] private float crouchSpeed = 1.5f;
    [SerializeField] private float gravity     = -18f;
    [SerializeField] private LayerMask groundLayer;

    [Header("Camera")]
    [SerializeField] private Transform cameraTarget;
    [SerializeField] private float mouseSensitivity = 2.0f;
    [SerializeField] private float verticalClampMin = -40f;
    [SerializeField] private float verticalClampMax =  60f;

    [Header("Crouch")]
    [SerializeField] private float standHeight  = 1.8f;
    [SerializeField] private float crouchHeight = 1.0f;
    [SerializeField] private float crouchTransitionSpeed = 8f;

    [Header("Flashlight")]
    [SerializeField] private GameObject flashlightObject;
    [SerializeField] private float flashlightBattery    = 100f;
    [SerializeField] private float drainRatePerSecond   = 0.5f;
    [SerializeField] private float criticalBatteryLevel = 15f;

    [Header("Audio")]
    [SerializeField] private AudioSource footstepSource;
    [SerializeField] private AudioClip[] footstepClips;
    [SerializeField] private float stepWalk   = 0.55f;
    [SerializeField] private float stepSprint = 0.33f;
    [SerializeField] private float stepCrouch = 0.80f;
    [SerializeField] private AudioSource heartbeatSource;

    private CharacterController _cc;
    private Vector3 _velocity;
    private float _cameraPitch, _footstepTimer, _flickerTimer, _fearLevel;
    private bool  _isSprinting, _isCrouching, _flashlightOn, _isGrounded;
    private Light _flashlight;
    private float _origIntensity;

    [HideInInspector] public float HealthPercent = 100f;

    private void Awake()
    {
        _cc = GetComponent<CharacterController>();
        _cc.height = standHeight;
        if (flashlightObject != null)
        {
            _flashlight    = flashlightObject.GetComponentInChildren<Light>();
            _origIntensity = _flashlight ? _flashlight.intensity : 1f;
            flashlightObject.SetActive(false);
        }
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible   = false;
    }

    private void Update()
    {
        HandleGroundCheck();
        HandleCameraRotation();
        HandleCrouch();
        HandleMovement();
        HandleFlashlight();
        HandleFootsteps();
        HandleHeartbeat();
    }

    private void HandleMovement()
    {
        float h = Input.GetAxisRaw("Horizontal");
        float v = Input.GetAxisRaw("Vertical");
        _isSprinting = Input.GetKey(KeyCode.LeftShift) && !_isCrouching && v > 0f;
        float speed  = _isCrouching ? crouchSpeed : _isSprinting ? sprintSpeed : walkSpeed;
        Vector3 move = (transform.right * h + transform.forward * v).normalized * speed;
        if (_isGrounded && _velocity.y < 0f) _velocity.y = -2f;
        _velocity.y += gravity * Time.deltaTime;
        move.y = _velocity.y;
        _cc.Move(move * Time.deltaTime);
    }

    private void HandleCameraRotation()
    {
        transform.Rotate(Vector3.up * Input.GetAxis("Mouse X") * mouseSensitivity);
        _cameraPitch -= Input.GetAxis("Mouse Y") * mouseSensitivity;
        _cameraPitch  = Mathf.Clamp(_cameraPitch, verticalClampMin, verticalClampMax);
        cameraTarget.localRotation = Quaternion.Euler(_cameraPitch, 0f, 0f);
    }

    private void HandleCrouch()
    {
        if (Input.GetKeyDown(KeyCode.C) || Input.GetKeyDown(KeyCode.LeftControl))
        { if (_isCrouching) TryStandUp(); else _isCrouching = true; }
        float t = _isCrouching ? crouchHeight : standHeight;
        _cc.height = Mathf.Lerp(_cc.height, t, crouchTransitionSpeed * Time.deltaTime);
        _cc.center = new Vector3(0f, _cc.height * .5f, 0f);
    }

    private void TryStandUp()
    {
        if (!Physics.SphereCast(transform.position + Vector3.up * crouchHeight,
            _cc.radius, Vector3.up, out _, standHeight - crouchHeight))
            _isCrouching = false;
    }

    private void HandleGroundCheck() =>
        _isGrounded = Physics.SphereCast(
            transform.position + Vector3.up * .1f, _cc.radius * .9f,
            Vector3.down, out _, .3f, groundLayer);

    private void HandleFlashlight()
    {
        if (Input.GetKeyDown(KeyCode.F))
        { _flashlightOn = !_flashlightOn; flashlightObject.SetActive(_flashlightOn); }
        if (!_flashlightOn || !_flashlight) return;
        flashlightBattery = Mathf.Clamp(flashlightBattery - drainRatePerSecond * Time.deltaTime, 0f, 100f);
        if (flashlightBattery <= 0f) { flashlightObject.SetActive(false); _flashlightOn = false; return; }
        if (flashlightBattery <= criticalBatteryLevel)
        {
            _flickerTimer -= Time.deltaTime;
            if (_flickerTimer <= 0f)
            { _flashlight.intensity = _origIntensity * Random.Range(.1f,1f); _flickerTimer = Random.Range(.05f,.25f); }
        }
        else _flashlight.intensity = _origIntensity * (flashlightBattery / 100f);
    }

    private void HandleFootsteps()
    {
        if (!_isGrounded || footstepClips == null || footstepClips.Length == 0) return;
        if (new Vector3(_cc.velocity.x, 0f, _cc.velocity.z).magnitude < 0.1f) return;
        float interval = _isCrouching ? stepCrouch : _isSprinting ? stepSprint : stepWalk;
        _footstepTimer -= Time.deltaTime;
        if (_footstepTimer <= 0f)
        {
            footstepSource.PlayOneShot(footstepClips[Random.Range(0, footstepClips.Length)],
                _isCrouching ? .4f : _isSprinting ? 1f : .7f);
            _footstepTimer = interval;
        }
    }

    private void HandleHeartbeat()
    {
        if (!heartbeatSource) return;
        if (_isSprinting) _fearLevel = Mathf.Clamp01(_fearLevel + Time.deltaTime * .3f);
        heartbeatSource.volume = Mathf.Lerp(0f, .85f, _fearLevel);
        heartbeatSource.pitch  = Mathf.Lerp(.85f, 1.4f, _fearLevel);
    }

    public void  SetFearLevel(float v)  => _fearLevel = Mathf.Clamp01(v);
    public float GetFearLevel()         => _fearLevel;
    public bool  IsFlashlightOn()       => _flashlightOn;
    public float GetFlashlightBattery() => flashlightBattery;
    public bool  IsCrouching()          => _isCrouching;
    public bool  IsSprinting()          => _isSprinting;
}
